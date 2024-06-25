# laravel-sail-new-project

This shell script can be used to quickly setup a new Laravel project with Sail. It is assumed you have Docker installed with the WSL option enabled.

1) Open a WSL shell
2) git clone git@github.com:nsanden/laravel-sail-new-project.git
3) cd lararavel-sail-new-project
4) `chmod +x startproject.sh`
5) `./startproject.sh project-name` (where project-name is lowercase with dashes instead of spaces)

This will

1) create a directory in the current directory called `name`
2) create a new Laravel project inside this directory and install Sail
3) create the docker-compose.yml file with an additional setting to add PHPMyAdmin
4) add sail to bashrc if needed

Once the sript finishes, just cd into the new directory and then:
1) `sail up -d`
2) `npm install`
3) `npm run dev`
