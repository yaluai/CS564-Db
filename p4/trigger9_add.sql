-- description: When latest bid is over buy_price, prevent more bids.

PRAGMA foreign_keys = ON;

drop trigger if exists trigger9;

create trigger trigger9
	before insert on Bids
	for each row when (Select i.ItemID from Items i where i.ItemID = NEW.ItemID and i.Currently >= i.Buy_Price)
	begin
		SELECT raise(rollback, 'Trigger9_Failed');
	end;