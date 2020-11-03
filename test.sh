password= tr </dev/urandom -dc '123456789!@#$%qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c12

echo $password
