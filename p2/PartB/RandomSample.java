import java.sql.*;
import java.util.Random;
import java.util.Scanner;

public class RandomSample {

    private String queryStatement;
    private double k;
    private boolean create;
    private String new_table_name;
    private long seed;
    private Connection connection;
    private Statement statement;
    private String psql_url;

    public RandomSample(String queryStatement, double k, boolean create, String new_table_name, long seed, String psql_url)
            throws SQLException {
        this.queryStatement = queryStatement;
        this.k = k;
        this.create = create;
        this.new_table_name = new_table_name;
        this.seed = seed;
        this.connection = DriverManager.getConnection("jdbc:postgresql://localhost:5432/postgres", "postgres", "123456");
        this.statement = connection.createStatement();
        this.psql_url = psql_url;
    }

    public void execute() throws SQLException {
        statement.executeUpdate("DROP TABLE IF EXISTS PrintThenDeleteTable;");

        statement.executeQuery(queryStatement + ";");

        statement.executeUpdate("CREATE TABLE PrintThenDeleteTable AS (SELECT row_number() over () as rownum, * FROM (" + queryStatement + ") AS sq1);");

        int iterCount =0;
        int n = getCount();
        getRandomRows(n,iterCount++);

        printResults(false, n,iterCount++);

        Scanner scanner = new Scanner(System.in);
        System.out.println("would you need more sample? y/n");
        boolean need = scanner.nextLine().trim().equals("y");
        while (need) {
            printResults(need, n,iterCount++);
            System.out.println("would you need more sample? y/n");
            need = scanner.nextLine().trim().equals("y");
        }
        if (!need){
            System.out.println("Thank you very much for use this JDBC");
        }
    }


    public int getCount() throws SQLException {
        int n = 0;
        ResultSet rs = statement.executeQuery("SELECT count(*) FROM PrintThenDeleteTable;");
        while (rs.next()) n = rs.getInt(1);

        return n;
    }

    public void getRandomRows(double n, int iterCount) throws SQLException {
        if (k >= n) {
            System.out.println("The sample size you chose is >= the size of the table/query you requested");
            return;
        }

        double m = 0; //number selected so far
        double t = 0; //number seen so far
        Random rand = new Random(seed+iterCount);

        StringBuilder sb = new StringBuilder("(");
        while (m < k) {
            double u = rand.nextDouble();

            if ((n - t) * u < (k - m)) {
                m++;
                int row = (int) t + 1;
                sb.append(row);
                if (m != k) sb.append(",");
            }
            t++;
        }
        sb.append(")");

        statement.executeUpdate("DELETE FROM PrintThenDeleteTable WHERE rownum NOT IN " + sb.toString() + ";");
    }

    public void printResults(boolean need, int n, int iterCount) throws SQLException {
        if (need) {
            n = getCount();
            getRandomRows(n, iterCount++);
        }
        ResultSet rs1 = statement.executeQuery("SELECT * FROM PrintThenDeleteTable;");
        ResultSetMetaData rsmd = rs1.getMetaData();
        int col_count = rsmd.getColumnCount();

        while (rs1.next()) {
            for (int i = 1; i <= col_count; i++) {
                if (i > 1) System.out.print(", ");
                System.out.print(rsmd.getColumnName(i) + " " + rs1.getString(i));
            }
            System.out.println("");
        }
        rs1.close();
    }
}
