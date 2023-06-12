#!/bin/bash

# Create the certificates necessary for our tests:
#   - a root certificate authority
#   - a server running on localhost
#   - a client making authenticated requests to the server
#
# We generate these with openssl, but could try using the rcgen crate.
#
# To dump the content of a certificate, openssl x509 -in cert.csr -text

openssl genrsa -out root-CA.key 4096
openssl genrsa -out localhost-cert.key 4096
openssl genrsa -out client-cert.key 4096


# create the certificate for the root Certificate Authority
openssl req -x509 -new -nodes \
   -sha256 -days 1000 \
   -subj "/C=FR/L=Toulouse/O=Test" \
   -addext "basicConstraints=CA:true" \
   -key root-CA.key \
   -out root-CA.crt

# Create the certificate for the server on localhost. Note that rustls is finicky, requiring the
# subjectAltName field to be present.
openssl req -new -sha256 \
   -subj "/C=FR/L=Toulouse/O=Test/CN=localhost" \
   -addext 'subjectAltName=DNS:localhost' \
   -key localhost-cert.key \
   -out localhost-cert.csr
openssl x509 -req \
   -CAcreateserial -days 1000 -sha256 -copy_extensions copy \
   -in localhost-cert.csr \
   -CA root-CA.crt \
   -CAkey root-CA.key \
   -out localhost-cert.crt

# create the certificate for the client
openssl req -new -sha256 -nodes \
   -subj "/C=FR/L=Toulouse/O=Test/CN=local-test-client" \
   -addext "basicConstraints=CA:false" \
   -addext "extendedKeyUsage=clientAuth" \
   -key client-cert.key \
   -out client-cert.csr
openssl x509 -req \
   -CAcreateserial -days 1000 -sha256 -copy_extensions copy \
   -CA root-CA.crt \
   -CAkey root-CA.key \
   -in client-cert.csr \
   -out client-cert.crt
# The client_id is a PEM encoded private key and at least one PEM encoded certificate.
cat client-cert.key client-cert.crt > client-id.pem


# For this test setup, we don't need to keep the key for the root CA nor the signing requests.
# Keep all the certificates and keys in the fixtures/ directory.
rm root-CA.key localhost-cert.csr client-cert.csr
mv root-CA.crt localhost-cert.key localhost-cert.crt client-cert.key client-cert.crt fixtures
mv client-id.pem fixtures


