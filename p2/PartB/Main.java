
import java.sql.SQLException;

import java.util.Scanner;

public class Main {

    public static void main(String[] args) throws SQLException {

        long seed = System.nanoTime();
        String psql_url = "";
        Scanner scanner = new Scanner(System.in);
        // Accept a table name or a query
        System.out.println("Would you like to sample from a table or query? (table/query)");
        boolean query = scanner.nextLine().trim().equals("query");
        String query_statement = null;
        if (query) {
            System.out.println("Please enter the query statement without ';': ");
            query_statement = scanner.nextLine();
        } else {
            System.out.println("Please enter the table name: ");
            String table_name = scanner.nextLine().trim();
            query_statement = "SELECT * FROM " + table_name;
        }


        // Ask for how many sample rows are desired
        System.out.println("Enter how many rows you would like to sample: ");
        double k = Double.valueOf(scanner.nextLine().trim());


        // Ask if the user wants a table created for the sampled rows

        System.out.println("Would you like to save the sample rows to a table? (y/n)");
        boolean create_table = scanner.nextLine().trim().equals("y");
        String new_table_name = "PrintThenDeleteTable";
        if (create_table) {
            new_table_name = "Sample_" + System.currentTimeMillis();
            System.out.println("The created table will be named: " + new_table_name);
        }

        //  Allow the user to reset the seed of the random number generator
        System.out.println("Would you like to reset the seed for the random number generator: (y/n)");
        boolean reset = scanner.nextLine().trim().equals("y");
        if (reset) {
            seed = System.nanoTime();
            System.out.println("random number generator has been reset");
        }

        // Fetch/insert exactly that number of random samples from the table or query result

        RandomSample randomSample = new RandomSample(query_statement, k, create_table, new_table_name, seed, psql_url);
        randomSample.execute();



        ;
    }
}
