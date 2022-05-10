+++
loc_a = 7
loc_b = "septimia"
loc_c = 1//3
+++

# Landing page

## Links

* [Page 1](## page 1)
* [Page 2](## page 2)
* [Page 3](/page3/) (from raw html)

## Access to global variables

* expect 5: < {{glob_a}} >
* expect octavian: < {{glob_b}} >
* expect 1/2: < {{glob_c}} >


Note: `<{{...}}>` doesn't work but this might be due to something else

## Access to local variables

* expect 7: < {{loc_a}} >
* expect septimia: < {{loc_b}} >
* expect 1/3: < {{loc_c}} >

## E-strings on global and local variable

* `glob_a^2` expect 25: {{e"$glob_a^2"}} {{> $glob_a^2 }}
* `uppercase(glob_b)`: {{e"uppercase($glob_b)"}}
* `uppercase(loc_b)`: {{> uppercase($loc_b)}}

Note: `{{> ...}}` needs a space right of `>`.

## Hfun

* expect foo: < {{foo}} >
* expect octavian: < {{gvar glob_b}} >
* expect septimia: < {{lvar loc_b}} >

## e-string

* expect SEPTIMIA: < {{> uppercase($loc_b)}} >

## Asset

![](/assets/pangolin.jpg)
