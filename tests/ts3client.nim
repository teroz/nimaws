import unittest,os,asyncdispatch,httpclient,md5,osproc,strutils

import nimaws/s3client

suite "Test s3Client":
  
  var
    bucket = "tbteroz01"
    region = "us-west-2"
    passwd = findExe("passwd")
    client:S3Client
    md5sum = execProcess("md5sum " & passwd)
    creds:(string,string)
    
  test "AWS_ACCESS_ID and AWS_ACCESS_SECRET Exported": 
    require existsEnv("AWS_ACCESS_ID") 
    require existsEnv("AWS_ACCESS_SECRET")
    creds = (getEnv("AWS_ACCESS_ID"), getEnv("AWS_ACCESS_SECRET"))
    client = newS3Client(creds)

  test "List Buckets":
    let res = client.list_buckets()
    assert res.code == Http200

  test "List Objects":
    client = newS3Client(creds,region)
    let res = client.list_objects(bucket)
    assert res.code == Http200

  test "Put Object":
    var
      path = "files/passwd"
      payload = if fileExists(passwd): readFile(passwd) else: "some file content\nbla bla bla"
      res = client.put_object(bucket,path,payload)

    assert res.code == Http200

  test "Get Object":
    var
      path = "files/passwd"
      f: File

    let res = client.get_object(bucket, path)
    assert res.code == Http200
    assert md5sum.find(getMD5(res.body)) > -1

    
