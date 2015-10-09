version=2.5.4.1006
target=Cloudera_HiveJDBC_${version}.zip
wget https://downloads.cloudera.com/connectors/$target
unzip $target
mkdir Cloudera_HiveJDBC4_${version};
cd Cloudera_HiveJDBC4_${version}
unzip ../Cloudera_HiveJDBC4_${version}.zip
hs2=node1
cd ..

export CLASSPATH=$CLASSPATH:`pwd`/Cloudera_HiveJDBC4_${version}/*:`hadoop classpath`:/opt/cloudera/parcels/CDH-*/lib/hive/lib

table='jdbc_hive_test';
 
sudo -u hive hive <<EOF
drop table if exists $table;
create table $table (c1 int, c2 int) row format delimited fields terminated by '|';
exit;
EOF

echo "1|2" > test.txt
echo "3|4" >> test.txt

hadoop fs -put test.txt /user/hive/warehouse/$table/

sudo -u hive hive -e "select * from $table"
 
cat <<EOF > ClouderaJDBCHiveExample.java
import java.sql.*;
import java.math.*;
class ClouderaJDBCHiveExample {
  static String JDBCDriver = "com.cloudera.hive.jdbc4.HS2Driver";
  static String ConnectionURL = "jdbc:hive2://$hs2:10000";
  public static void main(String[] args) {
    Connection con = null; Statement stmt = null; ResultSet rs = null;
    String query = "select * from $table";
    try {
      Class.forName(JDBCDriver);
      con = DriverManager.getConnection(ConnectionURL);
      stmt = con.createStatement();
      rs = stmt.executeQuery(query);
 
      System.out.printf("%20s%20s\r\n", "c1", "c2");
      while(rs.next()) {
        BigDecimal Col1 = rs.getBigDecimal ("c1");
        BigDecimal Col2 = rs.getBigDecimal ("c2");
        System.out.printf("%20s%20s\r\n", Col1.toString(), Col2.toString()); }
    } catch (SQLException se) {
      se.printStackTrace();
    } catch (Exception e) {
      e.printStackTrace();
    } finally {
      try {if (rs != null) {
        rs.close();
      }
      } catch (SQLException se1) {}
      try { if (stmt!=null) {stmt.close();}}
      catch (SQLException se2) {}
      try { if (con!=null) {con.close();}}
      catch (SQLException se3) {se3.printStackTrace();}
    }
  }
}
EOF
 
. /opt/cloudera/parcels/CDH-*/lib/bigtop-utils/bigtop-detect-javahome
$JAVA_HOME/bin/javac -classpath $CLASSPATH:. ClouderaJDBCHiveExample.java
$JAVA_HOME/bin/java -classpath $CLASSPATH:. ClouderaJDBCHiveExample

rm -fr Cloudera_HiveJDBC*

sudo -u hive hive -e "DROP TABLE IF EXISTS $table"; 
