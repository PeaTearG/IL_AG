var apikey = ""
var apisecret = ""

var cred = btoa(apikey+":"+apisecret);


var headers = [
  {key: "Accept", value: "application/json" },
  {key: "Authorization", value: "Basic "+cred }
];

var log2Console = true; //Visible UI edit mode test panel
var log2Audit = false;  //Visible in audit logs

function log(msg) {
  var prefix = "IllumioLabels: ";
  msg = prefix + msg;
  if (log2Console)
      console.log(msg + "; ");
  if (log2Audit)
      auditLog(msg);
}

function parseResponse(response){
  var obj;
  if (!response) {
  log("No API response");
}else if (response.statusCode == 200 && response.data.length > 0) {
  obj  = JSON.parse(response.data);
}else{
  log("Request responded: "+response.statusCode);
}
  return obj;
}

var url = 'https://2x2demotest40.ilabs.io:8443/api/v2/orgs/1/labels';
var response = httpGet(url, headers);
var obj = parseResponse(response);

var lookup = {};
for (var item, i = 0; item = obj[i++];) {
  lookup[item.value] = item.href;
}


return {'illumio_labels': lookup}
