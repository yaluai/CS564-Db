/**
 * @author See Contributors.txt for code contributors and overview of BadgerDB.
 *
 * @section LICENSE
 * Copyright (c) 2012 Database Group, Computer Sciences Department, University of Wisconsin-Madison.
 */

#include "btree.h"
#include "filescan.h"
#include "exceptions/bad_index_info_exception.h"
#include "exceptions/bad_opcodes_exception.h"
#include "exceptions/bad_scanrange_exception.h"
#include "exceptions/no_such_key_found_exception.h"
#include "exceptions/scan_not_initialized_exception.h"
#include "exceptions/index_scan_completed_exception.h"
#include "exceptions/file_not_found_exception.h"
#include "exceptions/end_of_file_exception.h"
#include "exceptions/file_exists_exception.h"
#include "exceptions/page_pinned_exception.h"
#include "exceptions/page_not_pinned_exception.h"
#include "exceptions/hash_not_found_exception.h"


//#define DEBUG

namespace badgerdb
{

// -----------------------------------------------------------------------------
// BTreeIndex::BTreeIndex -- Constructor
// -----------------------------------------------------------------------------

BTreeIndex::BTreeIndex(const std::string & relationName,
		std::string & outIndexName,
		BufMgr *bufMgrIn,
		const int attrByteOffset,
		const Datatype attrType)
{
	std::ostringstream idxStr;
	idxStr << relationName << '.' << attrByteOffset;
	std::string indexName = idxStr.str(); // indexName is the name of the index file
	outIndexName = indexName;


	this->attributeType = attrType;
	this->attrByteOffset = attrByteOffset;
	this->bufMgr = bufMgrIn;
	leafOccupancy = 0;
	nodeOccupancy = 0;
	scanExecuting = false;

	IndexMetaInfo* metadata;
	Page* headerPage;
	Page* rootPage;

	try {
		file = new BlobFile(indexName, true);
	}
	catch (FileExistsException& e){
		file = new BlobFile(indexName, false);
		headerPageNum = file->getFirstPageNo();

		bufMgr->readPage(file, headerPageNum, headerPage);
		metadata = (IndexMetaInfo*) headerPage;
		if (strcmp(metadata->relationName, relationName.c_str()) != 0 || 
			metadata->attrType != attrType || metadata->attrByteOffset != attrByteOffset) {
			BufferUnPinPage(headerPageNum, false);
			throw BadIndexInfoException("Error: Matadata does not match");
		}
		rootPageNum = metadata->rootPageNo;
		BufferUnPinPage(headerPageNum, false);
		return ;
	}

	bufMgr->allocPage(file, headerPageNum, headerPage);
	bufMgr->allocPage(file, rootPageNum, rootPage);

	metadata = (IndexMetaInfo*) headerPage;
	strcpy(metadata->relationName, relationName.c_str());
	metadata->attrByteOffset = attrByteOffset;
	metadata->attrType = attrType;
	metadata->rootPageNo = rootPageNum;
	NonLeafNodeInt* root = (NonLeafNodeInt*) rootPage;
	root->level = 1;
	initNonLeafNode(root);

	try {
		FileScan fileScan(relationName, bufMgr);
		RecordId scanRid = {};
		int cnt = 0;
		while (1) {
			fileScan.scanNext(scanRid);
			std::string recordStr = fileScan.getRecord();
			insertEntry( (int*) recordStr.c_str() + attrByteOffset, scanRid);
			cnt++;
			//if (cnt >= 100) break;
		}
	}
	catch (EndOfFileException e) {
		//std::cout << "B+ Tree Index Read all records" << std::endl;
	}
	BufferUnPinPage(headerPageNum, true);
	BufferUnPinPage(rootPageNum, true);
	return ;
}


// -----------------------------------------------------------------------------
// BTreeIndex::~BTreeIndex -- destructor
// -----------------------------------------------------------------------------

BTreeIndex::~BTreeIndex()
{
	if (scanExecuting) {
		try {
			endScan();
		}
		catch (ScanNotInitializedException e) {
		}
	}
	bufMgr->flushFile(file);
	delete file;
}

// -----------------------------------------------------------------------------
// BTreeIndex::insertEntry
// -----------------------------------------------------------------------------

const void BTreeIndex::insertEntry(const void *key, const RecordId rid) 
{
	Page* curPage;
	bufMgr->readPage(file, rootPageNum, curPage);

	NonLeafNodeInt* curNode = (NonLeafNodeInt*) curPage;

	LeafNodeInt* leafNode;

	int id;
	int k = *((int *) key);

    std::stack<PageId> sta;
	sta.push(rootPageNum);

	while (1) {
		for ( id = 0; id < INTARRAYNONLEAFSIZE && curNode->pageNoArray[id + 1] != Page::INVALID_NUMBER && curNode->keyArray[id] < k; id++);
		//for ( id = 0; id < INTARRAYNONLEAFSIZE - 1 && curNode->keyArray[id] != -1 && curNode->keyArray[id] < k; id++);

		if (id == 0 && curNode->pageNoArray[0] == Page::INVALID_NUMBER) {

			Page *leftPage, *rightPage;
			PageId leftPageId, rightPageId;
			bufMgr-> allocPage(file, leftPageId, leftPage);
			bufMgr-> allocPage(file, rightPageId, rightPage);

			curNode->keyArray[0] = k;
			curNode->pageNoArray[0] = leftPageId;
			curNode->pageNoArray[1] = rightPageId;

			LeafNodeInt* leftNode = (LeafNodeInt*) leftPage;
			LeafNodeInt* rightNode = (LeafNodeInt*) rightPage;
			leafNode = rightNode;

			//leafNode = (LeafNodeInt*) pageRight;
			leftNode->rightSibPageNo = rightPageId;

			initLeafNode(leftNode);
			initLeafNode(rightNode);
			BufferUnPinPage(leftPageId, true);

			sta.push(rightPageId);
			break;
		}

		bufMgr->readPage(file, curNode->pageNoArray[id], curPage);
		sta.push(curNode->pageNoArray[id]);


		if (curNode->level == 1) {
			leafNode = (LeafNodeInt*) curPage;
			break;
		}
		else {
			curNode = (NonLeafNodeInt*) curPage;
		}
	}

	if (!insertKeyIntoLeafNode(leafNode, k, rid)) {
		PageId newPageId = splitLeafNode(leafNode, k, rid);
		BufferUnPinPage(sta.top(), true);
		sta.pop();

		PageId curPageId = sta.top();
		bufMgr->readPage(file, curPageId, curPage);
		BufferUnPinPage(curPageId, true);
		curNode = (NonLeafNodeInt*) curPage;

		while (!insertKeyIntoNonLeafNode(curNode, k, newPageId)) {
			newPageId = splitNonLeafNode(curNode, k, newPageId);
			BufferUnPinPage(curPageId, true);
			sta.pop();

			if (sta.empty())
				break;
			curPageId = sta.top();
			bufMgr->readPage(file, curPageId, curPage);
			curNode = (NonLeafNodeInt*) curPage;
		}
		BufferUnPinPage(curPageId, true);

		if (sta.empty()) {
			Page* rootPage;
			PageId rootPageId;
			bufMgr->allocPage(file, rootPageId, rootPage);
			NonLeafNodeInt* root = (NonLeafNodeInt*) rootPage;
			root->level = 0;
			initNonLeafNode(root);

			root->keyArray[0] = k;
			root->pageNoArray[0] = curPageId;
			root->pageNoArray[1] = newPageId;

			rootPageNum = rootPageId;

			BufferUnPinPage(newPageId, true);
			BufferUnPinPage(rootPageId, true);
		}

	}
	while (!sta.empty()) {
		BufferUnPinPage(sta.top(), true);
		sta.pop();
	}
}

const bool BTreeIndex::insertKeyIntoNonLeafNode(NonLeafNodeInt* node, int key, PageId pageId) {
	if (node->pageNoArray[INTARRAYNONLEAFSIZE] != Page::INVALID_NUMBER)
		return false;

	int i;
	for (i = 0; i < INTARRAYNONLEAFSIZE && node->pageNoArray[i + 1] != Page::INVALID_NUMBER && node->keyArray[i] < key; i++);

	int j;
	for (j = i; node->pageNoArray[j + 1] != Page::INVALID_NUMBER; j++);

	for (int k = j; k > i; k--) {
		node->keyArray[k] = node->keyArray[k - 1];
		node->pageNoArray[k + 1] = node->pageNoArray[k];
	}
	node->keyArray[i] = key;
	node->pageNoArray[i + 1] = pageId;
	return true;
}

const bool BTreeIndex::insertKeyIntoLeafNode(LeafNodeInt *node, int key, const RecordId rid) {
	if (node->ridArray[INTARRAYLEAFSIZE - 1].page_number != Page::INVALID_NUMBER)
		return false;

	int i;
	for (i = 0; i < INTARRAYLEAFSIZE && node->ridArray[i].page_number != Page::INVALID_NUMBER && node->keyArray[i] < key; i++);

	int j;
	for (j = i; node->ridArray[j].page_number != Page::INVALID_NUMBER; j++);

	for (int k = j; k > i; k--) {
		node->keyArray[k] = node->keyArray[k - 1];
		node->ridArray[k] = node->ridArray[k - 1];
	}
	node->keyArray[i] = key;
	node->ridArray[i] = rid;
	return true;
}

const PageId BTreeIndex::splitNonLeafNode(NonLeafNodeInt* node, int &key, const PageId pageId) {
	Page* newPage;
	PageId newPageId;
	bufMgr->allocPage(file, newPageId, newPage);
	NonLeafNodeInt* newNode = (NonLeafNodeInt*) newPage;

	initNonLeafNode(newNode);
	int mid = (INTARRAYNONLEAFSIZE + 1 + 1) >> 1;

	int lastKey = INT_MIN;
	int keyArr[INTARRAYNONLEAFSIZE + 1];
	PageId pageNoArr[INTARRAYNONLEAFSIZE + 2];

	pageNoArr[0] = node->pageNoArray[0];

	int i, j;
	for (i = 0, j = 0; j < INTARRAYNONLEAFSIZE; i++) {
		if (lastKey <= key && key < node->keyArray[j]) {
			keyArr[i] = key;
			pageNoArr[i] = pageId;
			lastKey = node->keyArray[j];
			continue;
		}
		lastKey = keyArr[i] = node->keyArray[j];
		pageNoArr[i + 1] = node->pageNoArray[j + 1];
		j++;
	}

	if (i == j) {
		keyArr[i] = key;
		pageNoArr[i + 1] = pageId;
	}

	node->pageNoArray[0] = pageNoArr[0];

	for (int i = 0; i < mid; i++) {
		node->keyArray[i] = keyArr[i];
		node->pageNoArray[i + 1] = pageNoArr[i + 1];
	}

	newNode->pageNoArray[0] = pageNoArr[mid + 1];

	for (i = mid; i <INTARRAYNONLEAFSIZE; i++) {
		newNode->keyArray[i - mid] = keyArr[i + 1];
		newNode->pageNoArray[i - mid + 1] = pageNoArr[i + 2];
	}
	initNonLeafNode(node, mid);
	initNonLeafNode(newNode, mid - 1);

	newNode->level = node->level;

	key = keyArr[mid];

	BufferUnPinPage(newPageId, true);

	return newPageId;
}

const PageId BTreeIndex::splitLeafNode(LeafNodeInt *leftNode, int& key, const RecordId rid) {
	Page* rightPage;
	PageId rightPageId;
	bufMgr->allocPage(file, rightPageId, rightPage);
	LeafNodeInt* rightNode = (LeafNodeInt*) rightPage;

	initLeafNode(rightNode);

	int mid = (INTARRAYLEAFSIZE + 1) >> 1;
	for (int i = mid; i < INTARRAYLEAFSIZE; i++) {
		rightNode->keyArray[i - mid] = leftNode->keyArray[i];
		rightNode->ridArray[i - mid] = leftNode->ridArray[i];
	}
	initLeafNode(leftNode, mid);

	rightNode->rightSibPageNo = leftNode->rightSibPageNo;
	leftNode->rightSibPageNo = rightPageId;

	if (key >= rightNode->keyArray[0])
		insertKeyIntoLeafNode(rightNode, key, rid);
	else
		insertKeyIntoLeafNode(leftNode, key, rid);

	key = rightNode->keyArray[0];

	BufferUnPinPage(rightPageId, true);

	return rightPageId;
}

const inline void BTreeIndex::initLeafNode(LeafNodeInt* node, int start, int end) {
	for (int i = start; i < end; i++) {
		node->keyArray[i] = -1;
		node->ridArray[i].page_number = Page::INVALID_NUMBER;
		node->ridArray[i].slot_number = Page::INVALID_SLOT;
	}
}

const inline void BTreeIndex::initNonLeafNode(NonLeafNodeInt* node, int start, int end) {
	for (int i = start; i < end; i++) {
		node->keyArray[i] = -1;
		node->pageNoArray[i] = Page::INVALID_NUMBER;
	}
	node->pageNoArray[end] = Page::INVALID_NUMBER;
}

const void BTreeIndex::BufferUnPinPage(const PageId pageNo, const bool dirty) {
	try {
		bufMgr->unPinPage(file, pageNo, dirty);
	}
	catch (PageNotPinnedException& e){

	}
	catch (HashNotFoundException& e) {

	}

}

// -----------------------------------------------------------------------------
// BTreeIndex::startScan
// -----------------------------------------------------------------------------

const void BTreeIndex::startScan(const void* lowValParm,
				   const Operator lowOpParm,
				   const void* highValParm,
				   const Operator highOpParm)
{
   	if ((lowOpParm != GT && lowOpParm != GTE) || (highOpParm != LT && highOpParm != LTE)) {
		throw BadOpcodesException();
	}
	lowOp = lowOpParm;
	highOp = highOpParm;
	lowValInt = *(int *)lowValParm;
	highValInt = *(int *)highValParm;

	if (lowValInt > highValInt)
		throw BadScanrangeException();
	
	if (scanExecuting)
		endScan();

	nextEntry = getScanStartNodeForNextEntry(rootPageNum);
	scanExecuting = true;
}

const int BTreeIndex::getScanStartNodeForNextEntry(PageId pageNum) {
	currentPageNum = pageNum;
	bufMgr->readPage(file, currentPageNum, currentPageData);
	NonLeafNodeInt* curNode = (NonLeafNodeInt*) currentPageData;
	int i = 0;
	for (; i < INTARRAYNONLEAFSIZE && curNode->pageNoArray[i + 1] != Page::INVALID_NUMBER && curNode->keyArray[i] <= lowValInt; i++);

	if (curNode->level == 1) {
		BufferUnPinPage(currentPageNum, false);

		currentPageNum = curNode->pageNoArray[i];
		bufMgr->readPage(file, currentPageNum, currentPageData);

		LeafNodeInt* curNode = (LeafNodeInt*) currentPageData;

		int l = 0, r = INTARRAYLEAFSIZE - 1;
		
		int j = 0;
		for (j = l; j <= r; j++)
			if (lowOp == GT) {
				if (curNode->keyArray[j] > lowValInt) {
					return j;
				}
			}
			else {
				if (curNode->keyArray[j] >= lowValInt) {
					return j;
				}
			}
		return j;
	}

	BufferUnPinPage(currentPageNum, false);
	return getScanStartNodeForNextEntry(curNode->pageNoArray[i]);
}


// -----------------------------------------------------------------------------
// BTreeIndex::scanNext
// -----------------------------------------------------------------------------

const void BTreeIndex::scanNext(RecordId& outRid) 
{
	if (scanExecuting == false)
		throw ScanNotInitializedException();

	LeafNodeInt* curNode = (LeafNodeInt*) currentPageData;

	while (1) {
		if (nextEntry == INTARRAYLEAFSIZE) {
			BufferUnPinPage(currentPageNum, false);

			if (curNode->rightSibPageNo == Page::INVALID_NUMBER)
				throw IndexScanCompletedException();

			nextEntry = 0;
			currentPageNum = curNode->rightSibPageNo;
			bufMgr->readPage(file, currentPageNum, currentPageData);
			curNode = (LeafNodeInt*) currentPageData;
		}

		if (curNode->ridArray[nextEntry].page_number == Page::INVALID_NUMBER) {
			nextEntry = INTARRAYLEAFSIZE;
			continue;
		}

		if (lowOp == GT) {
			if (curNode->keyArray[nextEntry] <=lowValInt){
				nextEntry++;
				continue;
			}
				
		}
		else{
			if (curNode->keyArray[nextEntry] < lowValInt){
				nextEntry++;
				continue;
			}
		}

		if (highOp == LT){
			if (curNode->keyArray[nextEntry] >= highValInt)
				throw IndexScanCompletedException();
		}
		else {
			if (curNode->keyArray[nextEntry] > highValInt)
				throw IndexScanCompletedException();
		}

		break;
	}
	outRid = curNode->ridArray[nextEntry];
	nextEntry++;
}

// -----------------------------------------------------------------------------
// BTreeIndex::endScan
// -----------------------------------------------------------------------------
//
const void BTreeIndex::endScan() 
{
	if (scanExecuting == false)
		throw ScanNotInitializedException();

	scanExecuting = false;
	BufferUnPinPage(currentPageNum, false);
	return ;
}

}
