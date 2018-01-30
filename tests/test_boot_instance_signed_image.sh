#!/usr/bin/env bash

# Download image to environment
wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img


openssl genrsa -out private_key.pem 1024
openssl req -new -key private_key.pem -out cert_request.csr
openssl x509 -req -days 14 -in cert_request.csr -signkey private_key.pem -out new_cert.crt

openstack secret store --name test --algorithm RSA --secret-type certificate --payload-content-type "application/octet-stream" --payload-content-encoding base64 --payload "$(base64 new_cert.crt)"

cert_uuid=92ed303e-f1fd-4562-a2d5-78fa17a69d85

openssl dgst -sha256 -sign private_key.pem -sigopt rsa_padding_mode:pss -out myimage.signature cirros-0.3.5-x86_64-disk.img

base64 -w 0 myimage.signature > myimage.signature.b64

image_signature=$(cat myimage.signature.b64)

glance image-create --name mySignedImage --container-format bare --disk-format qcow2 --property img_signature="$image_signature" --property img_signature_certificate_uuid="$cert_uuid" --property img_signature_hash_method='SHA-256' --property img_signature_key_type='RSA-PSS' <  cirros-0.3.5-x86_64-disk.img
