#!/bin/bash

curl --location 'https://apix-uat.myanmarcitizensbank.com/AgencyBanking_27Oct/v1' \
  --header 'SOAPAction: http://uatcbs-api.mcb.net.mm:9093/AgencyBanking/services?wsdl' \
  --header 'Authorization: Bearer eyJ4NXQiOiJNV1V...' \
  --header 'Content-Type: text/xml' \
  --data-raw '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:agen="http://temenos.com/AgencyBanking">
<soapenv:Header/>
<soapenv:Body>
<agen:AgencyBankingAccountEnquiry>
<WebRequestCommon>
<company>MM0010001</company>
<password>TEST@789</password>
<userName>AGBUSER01</userName>
</WebRequestCommon>
<AGBGETCUSTBYACType>
<enquiryInputCollection>
<columnName>ACCOUNT.NUMBER</columnName>
<criteriaValue>100160010000272</criteriaValue>
<operand>EQ</operand>
</enquiryInputCollection>
</AGBGETCUSTBYACType>
</agen:AgencyBankingAccountEnquiry>
</soapenv:Body>
</soapenv:Envelope>'
