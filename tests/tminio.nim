import unittest,os,httpclient,md5,osproc,strutils,posix,terminal,streams,xmlparser,xmltree

import nimaws/s3client


from posix import SIGINT, SIGTERM
onSignal(SIGPIPE):
  styledEcho(fgRed,"SIG PIPE seen")

suite "Test Minio Endpoint":

  
  when not existsEnv("MINIO_ACCESS_ID") and not existsEnv("MINIO_ACCESS_SECRET"):
    echo "To test a minio endpoint export MINIO_ACCESS_ID and MINIO_ACCESS_SECRET and optionally MINIO_ENDPOINT if not the default http://localhost:9000"
  else:
    var
      bucket = "tb0000"
      passwd = findExe("passwd")
      client:S3Client
      md5sum = execProcess("md5sum " & passwd)


    const credentials = (getEnv("MINIO_ACCESS_ID"), getEnv("MINIO_ACCESS_SECRET"))
    const endpoint = getEnv("MINIO_ENDPOINT")
    const host = if endpoint.len == 0: "http://localhost:9000" else: endpoint
    const region = "us-west-1"
    client = newS3Client(credentials,region,host)


    test "List Buckets":
      
      var found: bool
      for b in client.list_buckets():
        if b.name == bucket:
          found = true
          break

      assert found
      
    test "Put Object":
      var
        path = "/files/passwd"
        payload = if fileExists(passwd): readFile(passwd) else: "some file content\nbla bla bla"
        res = client.put_object(bucket,path,payload)
  
      assert res.code == Http200
  # test "Test SSL remote reset":
    #   var 
    #     hostname = host.substr(host.find("://")+3)
    #     p  = startProcess(findExe("sudo"),args=[findExe("tcpkill"),"host  ",hostname],options={poEchoCmd,poStdErrToStdOut})
    #     s =  p.outputStream()
    #     line = ""

    #   while s.readLine(line):
    #       styledEcho(fgGreen,line)
    #       if line.find(">") > -1:
    #           break
    #   p.kill()
    #   p.close()
    #   s.close()    
   
    #   let res = client.list_buckets()
    #   assert res.code == Http200
    
    test "List Objects":
      let res = client.list_objects(bucket)
      var found:bool
      for f in res:
        if f.name == "files/passwd":
          found = true
          break

      assert found

    
    test "Get Object":
      var
        path = "/files/passwd"
        f: File

      let res = client.get_object(bucket, path)
      assert res.code == Http200
      assert md5sum.find(getMD5(res.body)) > -1




