#[
  # S3Client

  A simple object API for performing (limited) S3 operations
 ]#

import strutils except toLower
import times, unicode, tables, httpclient,streams,os,strutils,uri,streams,xmlparser,xmltree
import awsclient


type
  S3Client* = object of AwsClient
  

proc newS3Client*(credentials:(string,string),region:string=defRegion,host:string=awsEndpt):S3Client=
  let
    creds = AwsCredentials(credentials)
    # TODO - use some kind of template and compile-time variable to put the correct kernel used to build the sdk in the UA?
    httpclient = newHttpClient("nimaws-sdk/0.1.1; "&defUserAgent.replace(" ","-").toLower&"; darwin/16.7.0")
    scope = AwsScope(date:getAmzDateString(),region:region,service:"s3")
  var endpoint:string
  if not host.startsWith("http"): 
    endpoint = "https://" & host
  else:
    endpoint = host
  return S3Client(httpClient:httpclient, credentials:creds, scope:scope, endpoint:parseUri(endpoint),isAWS:endpoint.endsWith(awsEndpt),key:"", key_expires:getTime())

method get_object(self:var S3Client,bucket,key:string) : Response {.base.} =
  var
    path = key
  let params = {
        "bucket":bucket,
        "path": path
      }.toTable

  return self.request(params)

#
## put_object
##  bucket name
##  path has to be absoloute path in the form /path/to/file
##  payload is binary string
method put_object*(self:var S3Client,bucket,path:string,payload:string) : Response {.base,gcsafe.} =
  let params = {
      "action": "PUT",
      "bucket": bucket,
      "path": path,
      "payload": payload
    }.toTable

  return self.request(params)

# method list_objects*(self:var S3Client, bucket: string) : Response {.base,gcsafe.} =
#   let params = {
#       "bucket": bucket
#     }.toTable

#   return self.request(params)

method list_buckets(self:var S3Client) : Response {.base,gcsafe.} =
  let params = {
      "action": "GET"
    }.toTable

  return self.request(params)

proc parse(date:string):Datetime=
  var 
      c = date.find('.')
      t:string
  if c > -1:
    t = date.substr(0,c-1)
  else:
    t = date
    t.removeSuffix({'Z'})
  result = parse(t,"yyyy-MM-dd'T'HH:mm:ss",utc())

proc list_buckets*(client:var S3Client):seq[tuple[name:string,created:DateTime]]=
  let 
    params = {
      "action": "GET"
      }.toTable
    res = client.request(params)
  assert res.code == Http200
  var doc = newStringStream(res.body)
  for i in doc.parseXml.findAll "Bucket":
    result.add(( name: i.child("Name").innerText,
                       created: parse(i.child("CreationDate").innerText)))
  doc.close()


proc list_objects*(client:var S3Client,bucket:string):seq[tuple[name:string,created:DateTime]]=
  let 
    params = {
      "bucket": bucket
    }.toTable
    res = client.request(params)
  assert res.code == Http200
  
  var doc = newStringStream(res.body)
  for i in doc.parseXml.findAll "Contents":
    result.add(( name: i.child("Key").innerText,
                        created: parse(i.child("LastModified").innerText)))
  doc.close()

    
proc get_object*(client: var S3Client,bucket,key,path:string):bool=
    let res = client.get_object(bucket, key)
    if res.code == Http200:
      writeFile(path,res.body)  
      result = true

  