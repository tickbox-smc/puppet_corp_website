define corp_website::db (
        $user = hiera('corp_website::db_username'),
        $password = hiera('corp_website::db_password'),
        $rootpassword = hiera('corp_website::root_password'),
        $host = $::clientcert,
        $database = $name,
        $port = 3306
){
        #This file holds SQL statements to create database tables in MySQL
        file { '/tmp/mysql.sql':
                ensure => file,
                content => "use $database; CREATE TABLE countdetail (Id int(11) NOT NULL AUTO_INCREMENT,  Section varchar(500) NOT NULL,  `Date` date NOT NULL,  IP varchar(50) DEFAULT NULL,  PRIMARY KEY (Id)) ENGINE=InnoDB  DEFAULT CHARSET=latin1;",
        }

        #Install a MySQL server and listen to all IP-addresses
        class { '::mysql::server':
           create_root_user => true,
           root_password => $rootpassword,
           remove_default_accounts => true,
           restart => true,
           override_options => {
             mysqld => {
               bind-address => '0.0.0.0'
             },
           }
        }
        
        #Create a database and calling MySQL statement file.
        mysql::db { $name:
           user => $user,
           password => $password,
           host => "%",
           sql => "/tmp/mysql.sql",
           grant => ["ALL"]
        }
}

#Important part of the code: here we define our service resource and bind our variables to the attributes
Corp_website::Db produces Sql {
        user => $user,
        password => $password,
        host => $host,
        database => $database,
        port => $port
}