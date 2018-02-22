#!/bin/bash

set -e

keys=()
values=()
defaults=()

function add_setting {
	keys+=("$1")
	defaults+=("$2")
}

function get_setting {
  for ((i=0;i<${#keys[@]};++i)); do
    if [ "$1" = "${keys[i]}" ]; then
      echo "${values[i]}"
      return
    fi
  done
  echo "Setting \"$1\" not found"
  exit 1    
}


# define settings

add_setting name shibboleth
add_setting cert_dir "~/secure/shibboleth"
add_setting metadata https://haka.funet.fi/metadata/haka_test_metadata_signed.xml
add_setting metadata_cert https://wiki.eduuni.fi/download/attachments/27297785/haka_testi_2015_sha2.crt
add_setting discovery_service https://testsp.funet.fi/shibboleth/WAYF
add_setting support your@support.email


# parse arguments

for key in "$@"; do
  for ((i=0;i<${#keys[@]};++i)); do
    if [ "$1" = "--${keys[i]}" ]; then
      values[i]="$2"; shift 2
      continue
    fi
  done
done


# prompt for missing values
echo ""

for ((i=0;i<${#keys[@]};++i)); do
  if [ -z "${values[i]}" ]; then
    echo "set ${keys[i]} [${defaults[i]}]: 	"
    read value
    if [ -z "$value" ]; then
  	  values[i]="${defaults[i]}"
  	else
  	  values[i]="$value"
  	fi
  fi
done

  
# print settings
# for ((i=0;i<${#keys[@]};++i)); do 
#  echo "${keys[i]}: 	${values[i]}"
# done
# echo ""

name="$(get_setting name)"

# build an image with apache and shibd

if [[ ! $(oc get bc shibboleth 2> /dev/null) ]]; then
  oc new-build --name shibboleth -D - < dockerfiles/shibboleth/Dockerfile
  sleep 1
  oc logs -f bc/shibboleth
else
  echo "Using existing shibboleth build. Run the following commands to update it later:"
  echo "  bash update_dockerfile.bash shibboleth"
  echo "  oc start-build shibboleth --follow"
  echo ""
fi


# build for the java application

if [[ ! $(oc get bc shibboleth-java 2> /dev/null) ]]; then
  oc new-build -D - < dockerfiles/shibboleth-java/Dockerfile --name shibboleth-java
  oc start-build shibboleth-java --from-dir ../sso-test/ --follow
else
  echo "Using existing shibboleth-java build. Run the following commands to update it later:"
  echo "  bash update_dockerfile.bash shibboleth-java"
  echo "  oc start-build shibboleth-java --from-dir ../sso-test --follow"
  echo ""
fi


# deploy application

if [[ ! $(oc get dc "$name" 2> /dev/null) ]]; then
  oc new-app shibboleth-java --name "$name"
  oc expose dc "$name" --port=8000  	
  oc create route edge --service "$name" --port 8000 --insecure-policy=None
fi


# find out the route url

hostname="$(oc get route $name -o json | jq -r .spec.host)"
service_url="https://$hostname"

echo $service_url
echo ""


# configure apache

if [[ $(oc get secret "$name"-apache-conf 2> /dev/null) ]]; then
  	oc delete secret "$name"-apache-conf  
fi

cat templates/shibboleth.conf | sed -e "s#{{SERVICE_URL}}#$service_url#g" > tmp/shibboleth.conf
  	
oc create secret generic "$name"-apache-conf --from-file=shibboleth.conf=tmp/shibboleth.conf
rm tmp/shibboleth.conf


# configure shibd

if [[ $(oc get secret "$name"-shibd-conf 2> /dev/null) ]]; then
  	oc delete secret "$name"-shibd-conf  
fi

cat templates/shibboleth2.xml \
| sed -e "s#{{SERVICE_URL}}#$service_url#g" \
| sed -e "s#{{DISCOVERY_SERVICE}}#$(get_setting discovery_service)#g" \
| sed -e "s#{{SUPPORT}}#$(get_setting support)#g" \
| sed -e "s#{{METADATA}}#$(get_setting metadata)#g" \
> tmp/shibboleth2.xml

echo ""

# map all attributes
curl -s https://wiki.eduuni.fi/download/attachments/27297794/attribute-map.xml > tmp/attribute-map.xml
curl -s $(get_setting metadata_cert) > tmp/metadata.crt

# evaluate the "~" to absolute path
cert_dir="$(eval echo $(get_setting cert_dir))"

if [ ! -d $cert_dir ]; then
  echo "ERROR cert_dir $cert_dir does not exist"
  exit 1
fi

if [ ! -f $cert_dir/sp-key.pem ]; then
  echo "Private key $cert_dir/sp-key.pem does not exist. Generating it"
  pod_user="$(oc rsh dc/"$name" bash -c "id -u" | tr '\r' '\n')"
  pod_group="$(oc rsh dc/"$name" bash -c "id -u" | tr '\r' '\n')"
  oc rsh dc/"$name" shib-keygen -h $hostname -y 3 -e $service_url -o /tmp -u $pod_user -g $pod_group -f
  oc rsh dc/"$name" cat /tmp/sp-key.pem > $cert_dir/sp-key.pem
  oc rsh dc/"$name" cat /tmp/sp-cert.pem > $cert_dir/sp-cert.pem
  chmod go-rwx $cert_dir/sp-key.pem
  oc rsh dc/"$name" rm /tmp/sp-key.pem
  oc rsh dc/"$name" rm /tmp/sp-cert.pem  
  echo ""
else
  echo "Using existing private key $cert_dir/sp-key.pem"
fi
  	
oc create secret generic "$name"-shibd-conf \
  --from-file=shibboleth2.xml=tmp/shibboleth2.xml \
  --from-file=attribute-map.xml=tmp/attribute-map.xml \
  --from-file=sp-key.pem=$cert_dir/sp-key.pem \
  --from-file=sp-cert.pem=$cert_dir/sp-cert.pem \
  --from-file=metadata.crt=tmp/metadata.crt
  	
rm tmp/shibboleth2.xml
rm tmp/attribute-map.xml
rm tmp/metadata.crt
echo ""

if oc volume dc/"$name" --name shibd-conf > /dev/null 2>&1; then
	oc set volume dc/"$name" --remove --name shibd-conf
fi
if oc volume dc/"$name" --name apache-conf > /dev/null 2>&1; then
	oc set volume dc/"$name" --remove --name apache-conf
fi
oc set volume dc/"$name" --add -t secret --secret-name "$name"-shibd-conf --mount-path /etc/shibboleth/secret --name shibd-conf
oc set volume dc/"$name" --add -t secret --secret-name "$name"-apache-conf --mount-path /etc/apache2/sites-enabled --name apache-conf
echo ""

echo "---------------------------------------------------------------------------------------------"
echo "Register the service in Haka resource registry https://rr.funet.fi/rr"
echo ""
echo "** Organiztion information"
echo "Select your organization."
echo ""
echo "** SP Basic Information"
echo "Entity Id                                             $service_url"
echo "Service Name (Finnish)                                <fill-in>"    
echo "Service Description (Finnish)                         <fill-in>"    
echo "Service Login Page URL                                $service_url/Shibboleth.sso/Login"
echo "Discovery Response URL                                $service_url/Shibboleth.sso/Login"
echo "urn:oasis:names:tc:SAML:2.0:nameid-format:transient   x"
echo ""
echo "** SP SAML Endpoints"
echo "URL index #1                                          $service_url/Shibboleth.sso/SAML2/POST"
echo ""
echo "** Certificates"
echo "Copy the contents of the file $(get_setting cert_dir)/sp-cert.pem to the text field (without the first and "
echo "last line)."
echo ""
echo "** Requested Attributes"
echo "The test application uses these two attributes"
echo ""
echo "eduPersonPrincipalName                                x    Technical user identifier"
echo "cn                                                    x    Human-readable name of the user"
echo ""
echo "Select the additional attributes you need and explain why. See"
echo "- https://rr.funet.fi/haka/ (your own information)"
echo "- https://testsp.funet.fi/haka/ (you will get the test credentials after the registration)"
echo "- https://wiki.eduuni.fi/display/CSCHAKA/funetEduPersonSchema2dot2"
echo ""
echo "In Test-Haka, select at least the cn attribute, becuase the test user's name contains an "
echo "accented character, which allows us to test a character encoding issue later."
echo ""
echo "** UI Extensions"
echo "None"
echo ""
echo "** Contact Information"
echo "Contact type                                          Technical"
echo "First Name                                            <fill-in>"
echo "Last Name                                             <fill-in>"
echo "E-Mail                                                $(get_setting support)"
echo "Contact type                                          Support"
echo "First Name                                            <fill-in>"
echo "Last Name                                             <fill-in>"
echo "E-Mail                                                $(get_setting support)"
echo "--------------------------------------------------------------------------------------------"
echo ""
echo "If you want to delete all builds created by this script"
echo "    oc delete bc/shibboleth; oc delete is/shibboleth; oc delete bc/shibbboleth-java; oc delete is/shibboleth-java"
echo ""
echo "If you want to delete everything else"
echo "    oc delete dc/$name; oc delete route/$name; oc delete service/$name; oc delete secret $name-shibd-conf; oc delete secret $name-apache-conf"
echo ""   
