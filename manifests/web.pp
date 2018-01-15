define corp_website::web (
        $user,
        $password,
        $host,
        $database,
        $http_port = '8080',
        
){
        $website_version    =hiera('corp_website::version')
        $website_dns        =hiera('corp_website::dns')
        $counter_dns        =hiera('corp_website::counter_dns')
 
        #Require yum Gemfury repo
        require yum
        
        #Include apache

        class { 'apache':
         default_vhost => false,
         mpm_module      => 'prefork',
        }        
        
        apache::vhost { "$website_dns": 
          port            =>  "$http_port",
          docroot         => '/var/www/corp-website',
          default_vhost   => true,
        }
        
        apache::vhost { "$counter_dns": 
          port            =>  "$http_port",
          docroot         => '/var/www/html/counter',
        }
        
        #Include extra apache modules
        include '::apache::mod::php'

        class { '::mysql::bindings': php_enable => true, }
        
        file { 'index.html':
          ensure  => file,
          path    => '/var/www/corp-website/index.html',
          content => template('corp_website/index.html.erb'),
          require => Package['corp_website'],
        }
        
        file { 'configuration.php':
          ensure  => file,
          path    => '/var/www/html/counter/configuration.php',
          content => template('corp_website/configuration.php.erb'),
          require => Package['web_counter'],
        }
        
        #To clean Yum cache only when Puppet resources are modified
        exec { 'yum-clean-expire-cache':
          command => '/usr/bin/yum clean expire-cache',
          refreshonly => true,
        }
        
        #Install web_counter package
        package { 'web_counter' :
          ensure  => latest,
          require => Exec['yum-clean-expire-cache'],
        }
        
        #Install corp-website package
        package { 'corp_website' :
          ensure  => "$website_version", 
          require => Exec['yum-clean-expire-cache'],
        }
        
        #Allow Apache through SELinux to Talk to MySQL
        selboolean { 'httpd_can_network_connect_db':
          value     => on,
          persistent => true,
        }
}

#Multiple resource statements here: we define our consume statement and the produce statement.

#Note: produce, NOT export
Corp_website::Web consumes Sql {
        username => $user,
        password => $password,
        host => $host,
        database => $database,
        port => $port
}

Corp_website::Web produces Http {
        http_name => $::clientcert,
        http_ip => $::ipaddress,
        http_port => $http_port
}

