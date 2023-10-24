#/bin/sh

#infinite loop
for (( c=1; c<=5; c++ ))
do 
   curl -s -X GET http://*.*.*.com/ > /dev/null
   c=1
done