application corp_website (
        #the default number of web and lb servers I will have in my application. Can be overwritten via input parameters
        $number_webs = 1,
        $number_lbs = 1
) {
        #iterate X number of times and create a Http service resource with a unique name and store it in the $webs variable, along with a Lb service resource stored in the $lbs variable.
        $webs = $number_webs.map |$i| {Http["http-${name}-${i}"]}
        $lbs = $number_lbs.map |$i| {Lb["lb-${name}-${i}"]}
        
         #Definition of the database component. Here we define that the database component will export a SQL service resource

        corp_website::db { $name:
                export => Sql["corp_website-${name}"],
        }

        #Loop over the $webs variable and create a unique resource each time. In the definition we declare that the SQL service resource will be consumed and a HTTP service resource is exported
        #Creating Ruby array with the each method 
        $webs.each |$i, $web| {
                corp_website::web { "${name}-web-${i}":
                        consume => Sql["corp_website-${name}"],
                        export => $web,
                }
        }

        #Loop over the $lbs variable and create a unique resource each time.
        #The load balancer definition does not use export or consume statements. We just pass the $webs service resources as an input
        #note: we have a require statement here. This will halt the configuration of the load balancer until the HTTP service resources are created
        #Creating Ruby array with the each method 
        $lbs.each |$i, $lb| {
                corp_website::lb { "${name}-lb-${i}":
                        balancemembers => $webs,
                        require => $webs,
                }
        }
}