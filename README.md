# laravel-sail-new-project

This shell script can be used to quickly setup a new Laravel project with Sail. It is assumed you have Docker installed with the WSL option enabled.

1) `chmod 777 startproject.sh`
2) `./startproject.sh name`

This will

1) create a directory in the current directory called `name`
2) create a new Laravel project inside this directory and install Sail
3) create the docker-compose.yml file with an additional setting to add PHPMyAdmin
4) add sail to bashrc if needed

Once the sript finishes, just cd into the new directory and then:
1) `sail up -d`
2) `npm install`
3) `npm run dev`
