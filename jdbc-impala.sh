version=2.5.16.1018
target=impala_jdbc_${version}.zip
wget http://downloads.cloudera.com/connectors/$target
unzip $target
unzip $version/Cloudera_ImpalaJDBC41_${version}.zip
export CLASSPATH=$CLASSPATH:`pwd`/ImpalaJDBC41/*:`hadoop classpath`:/opt/cloudera/parcels/CDH-*/lib/hive/lib

table="jdbc_impala_test";
host=node2

impala-shell -i $host <<EOF
drop table if exists $table;
create table $table (col1 int, col2 int);
insert into $table values(1, 10);
exit;
EOF

cat <<EOF > ClouderaJDBCImpalaExample.java
    import java.sql.*;
    import java.math.*;

    class ClouderaJDBCImpalaExample {
        static String JDBCDriver = "com.cloudera.impala.jdbc41.Driver";
        static String ConnectionURL = "jdbc:impala://$host:21050";

        public static void main(String[] args) {
            Connection con = null; Statement stmt = null; ResultSet rs = null;
            String query = "select * from $table";
            try {
                Class.forName(JDBCDriver);
                con = DriverManager.getConnection(ConnectionURL);
                stmt = con.createStatement();
                rs = stmt.executeQuery(query);
                
                System.out.printf("%20s%20s\r\n", "col1", "col2");
                while(rs.next()) {
                BigDecimal Col1 = rs.getBigDecimal ("col1");
                BigDecimal Col2 = rs.getBigDecimal ("col2");
                System.out.printf("%20s%20s\r\n", Col1.toString(), Col2.toString()); }
            } catch (SQLException se) {
                se.printStackTrace();
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                try {
		    if (rs != null) {
                        rs.close();
                    }    
                } catch (SQLException se1) {}
                
		try { 
		    if (stmt!=null) {
		        stmt.close();
		    }
                } catch (SQLException se2) {}
		
                try { 
                    if (con!=null) {con.close();}
                } catch (SQLException se3) {se3.printStackTrace();}
            }
        }
    }
EOF

. /opt/cloudera/parcels/CDH-*/lib/bigtop-utils/bigtop-detect-javahome
$JAVA_HOME/bin/javac -classpath $CLASSPATH ClouderaJDBCImpalaExample.java
$JAVA_HOME/bin/java -classpath $CLASSPATH ClouderaJDBCImpalaExample

rm -fr $version
rm -fr $target
rm -fr ImpalaJDBC41
rm -f ClouderaJDBCImpalaExample.*

