  ////////////////////////////////////////////////////////////////////////////////////////////
 /////////////			Caching API							//////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////
/*
cache.get(key, functionToGetIfItsNotInCache) // will pass 1 day validity

cache.get(key, functionToGetIfItsNotInCache, validityDurationSeconds)

cache.getIfPresent(key) // will return the cached value if it hasn't expired. Otherwise null

cache.put(key, value) // will pass 1 day validity

cache.put(key, value, validityDurationSeconds)
*/
  //////////////////////////////////////////////////////////////////////////////////////////////
 /////////////			Set Up/Config						///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

var returnpublicIPs = false;
var returnprivateIPs = true;
var apikey = "";
var apisecret = "";
var baseurl = "";

var  assignedLabels = [['QA','AWS London']];  //use an array of array's to assign labels, a single label is too broad anyway. If there is only a single array of labels, make sure to nest it


var log2Console = true; //Visible UI edit mode test panel
var log2Audit = true;  //Visible in audit logs
function log(msg) {
	var prefix = "IllumioResolver: ";
	msg = prefix + msg;
	if (log2Console)
		console.log(msg + "; ");
	if (log2Audit)
		auditLog(msg);
};

var cred = btoa(apikey+":"+apisecret);
 
var headers = [
  {key: "Accept", value: "application/json" },
  {key: "Authorization", value: "Basic "+cred }
];

   /////////////////////////////////////////////////////////////////////////////////////////////
  /////////////			parsers                 			///////////////////////////////////
 /////////////////////////////////////////////////////////////////////////////////////////////



const parse = function(response){
	if (!response) {
		log("No reponse from api request");
	}else if (response.statusCode >= 200 && response.statusCode < 300 && response.data) {
		return JSON.parse(response.data);
	}else{
		log("Request failure [ "+response.statusCode+" ]:"+response.data);
	}
	return
}
parse.labels = function(input){
	log('parsing response from API call')
	return this(input)[0]['href']
}
parse.workloads = function(input){
	let re = /^(127(?:\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$)|(10(?:\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$)|(192\.168(?:\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){2}$)|(172\.(?:1[6-9]|2\d|3[0-1])(?:\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){2}$)/
	let ips = []
	log('parsing IPs')
	input.forEach(workload => {
		if(returnpublicIPs){
			ips.push(workload.public_ip)
		}
		if(returnprivateIPs){
			let privIPS = workload.interfaces.reduce((acc, val)=>{
        if(re.test(val.address)){
          acc.push(val.address)
        }
        return acc
      },[])
      ips = ips.concat(privIPS)
		}
	})
  return ips
}


   /////////////////////////////////////////////////////////////////////////////////////////////
  /////////////			Label to HREF queries first			///////////////////////////////////
 /////////////////////////////////////////////////////////////////////////////////////////////
///////https://docs.illumio.com/core/21.2/API-Reference/index.html#Illumio-Core-labels///////


function labelcacheOrQuery(query){
	return cache.get(query, () => {
		log(`${JSON.stringify(query)} not found in cache, making API call`)
		log(JSON.stringify(headers))
		log(`${baseurl}/labels?value=${query}`)
		let response = httpGet(encodeURI(`${baseurl}/labels?value=${query}`), headers);
		log(`${response.data}`)
		return parse.labels(response)
	})
}
    ////////////////////////////////////////////////////////////////////////////////////////////
   /////////////			Label to HREF queries first	         //////////////////////////////
  ////////////			Label Arrays to IPs					//////////////////////////////////
 ////////////////////////////////////////////////////////////////////////////////////////////
/////https://docs.illumio.com/core/21.2/API-Reference/index.html#Illumio-Core-workloads/////

function arraycacheOrQuery(query){
	return cache.get(query, () => {
		log(`${JSON.stringify(query)} not found in cache, making API call`)
		let response = httpGet(encodeURI(`${baseurl}/workloads?labels=${JSON.stringify(query)}`), headers);
		return parse(response)
	})
}
 

  //////////////////////////////////////////////////////////////////////////////////////////////
 /////////////			Label Arrays to IPs					///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

function arraymap(array){
	return array.map(label => labelcacheOrQuery(label))
}

function queryBuilder() {
	const ips = [];
	let workloadarray =  assignedLabels.map(labelgroup => arraymap(labelgroup))
	return parse.workloads(arraycacheOrQuery(workloadarray))
}
return queryBuilder()
