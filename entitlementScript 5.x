//I hate defining variables to I put everything in objects lol
// { "illumio_labels": { "dev": "/orgs/1/labels/16", "Development": "/orgs/1/labels/9", "Production": "/orgs/1/labels/7", "QA": "/orgs/1/labels/14", "Staging": "/orgs/1/labels/8", "Test": "/orgs/1/labels/10", "Amazon": "/orgs/1/labels/11", "AWS London": "/orgs/1/labels/18", "AWS NVirginia": "/orgs/1/labels/15", "Azure": "/orgs/1/labels/12", "Rackspace": "/orgs/1/labels/13", "API": "/orgs/1/labels/3", "Database": "/orgs/1/labels/2", "Load Balancer": "/orgs/1/labels/6", "Mail": "/orgs/1/labels/4", "Single Node App": "/orgs/1/labels/5", "Web": "/orgs/1/labels/1" } }
// claims.user.agScripted = { "illumio_labels": { "dev": "/orgs/1/labels/16", "Development": "/orgs/1/labels/9", "Production": "/orgs/1/labels/7", "QA": "/orgs/1/labels/14", "Staging": "/orgs/1/labels/8", "Test": "/orgs/1/labels/10", "Amazon": "/orgs/1/labels/11", "AWS London": "/orgs/1/labels/18", "AWS NVirginia": "/orgs/1/labels/15", "Azure": "/orgs/1/labels/12", "Rackspace": "/orgs/1/labels/13", "API": "/orgs/1/labels/3", "Database": "/orgs/1/labels/2", "Load Balancer": "/orgs/1/labels/6", "Mail": "/orgs/1/labels/4", "Single Node App": "/orgs/1/labels/5", "Web": "/orgs/1/labels/1" } };
claims.user.appColors = ["AWS London"]


const illumio = {
    baseurl: '',
    apikey: '',
    apisecret: '',
    ip_list: '/orgs/1/sec_policy/active/ip_lists/1492',
    workloadhref: [],
    ingress: [],
    ports: [],
  //  creds: btoa(`${this.apikey}:${this.apisecret}`),
    headers: function(){
        let _headers = [
            {key: "Accept", value: "application/json" },
            {key: "Authorization", value: "Basic "+btoa(`${this.apikey}:${this.apisecret}`) }
        ]
        return _headers;
    },
    inputvalidation: function() {
        if (claims.user.agScripted && claims.user.appColors){
            return ('illumio_labels' in claims.user.agScripted);
        }else{
            return false;
        }
    },
    querybuilder: function() {
            this.index = claims.user.agScripted['illumio_labels'];
            let _querys = [];
            this.LB_href = this.index["QA"];
            for (let label of claims.user.appColors) {
                _querys.push(`[["${this.index[label]}","${this.LB_href}"]]`);
            }
            return _querys;
    },
    resolve: function() {
        if (this.inputvalidation()){
            this.combiresponse = [];
            for (let query of this.querybuilder()) {
                let url = encodeURI(this.baseurl+'/orgs/1/workloads?labels='+query);
                let response = httpGet(url, this.headers());
                let data = reqhandle.parse(response, url);
                let priv = data ? this.privateips(data):[];
                if (priv){
                for (let i of priv){
                    this.combiresponse.push(i);
                }
            }
                //this.workloadhref.push(data[0]['href']);
            }
            return this.combiresponse;
        }else{
            return false
        }
    },
    privateips: function(data){
      const response = [];
      for (let i in data){
        for (let ii of data[i].interfaces){
          response.push(ii);
        }
      }
        //let response = let i of data[0].interfaces
        const addresses = [];
        for  (let i of response){
            ((i.name.indexOf("public") !== -1) || (i.address.indexOf(":") !== -1)) ? {} : addresses.push(i.address)
        }
        return addresses
    },
    rulestoservices: function(){
        if (this.inputvalidation()){
            for(let query of this.querybuilder()){
                let url = encodeURI(this.baseurl + '/orgs/1/sec_policy/active/rule_sets?scopes='+query);
                let response = httpGet(url, this.headers());
                let data = reqhandle.parse(response, url);
                for(let components of data){
                    for(let rule of components.rules){
                        for(let consumer of rule.consumers){
                            if ('ip_list' in consumer){
                                if(consumer.ip_list.href === this.ip_list){
                                    for(let service of rule.ingress_services){
                                        let hreftoadd = service.href;
                                        if(this.ingress.indexOf(hreftoadd) == -1){
                                            this.ingress.push(service.href);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return true //apart of the first if statement
        }else{
            return false;
        }
    },
    servicestoports: function(){ //no input validation here because this will be called after rulestoservices
        for(let service of this.ingress){
            console.log(service);
            let url = encodeURI(this.baseurl + service);
            let response = httpGet(url, this.headers());
            let data = reqhandle.parse(response, url);
            for(let i of data.service_ports){
                if(this.ports.indexOf(i.port) == -1){
                    this.ports.push(i.port)
                }
            }
        }
        return this.ports;
    },
    portresolver: function(){
        if(this.rulestoservices()){
            return this.servicestoports();
        }else{
            return false
        }
    }
};

const reqhandle = {
    parse: function(_resp, _url) {
        if (!_resp) {
            console.log("No API response");
            return false
        }else if (_resp.statusCode == 200 && JSON.parse(_resp.data).length > 0) {
            return JSON.parse(_resp.data);
        }else {
            if(!_url) {
                _url = "API";
            }
            console.log(`unsuccessful resolution of ${_url} with a status code of ${_resp.statusCode}`)
            return false
        }
    }
};


//return illumio.resolve() //Uncomment this to resolve IP addresses from Illumio Labels
return illumio.resolve() //Uncomment this to auto populate the port field within an action ONLY TCP
