## About
vipeval is a backend service for ECS/ViP. It's running as a pure client i.e. there is no server running.

* You need Ruby 2.1.x installed
* No database needed

It's allowed to run multiple instances of vipeval. They work concurrently
on their ECS resources.

## Installation
Just download vipeval package ([github zip][vipeval-master_github.zip], [freeit tgz][vipeval-master_freeit.tgz])
and unpack or clone it from git repository ([github][github-repo], [freeit][freeit-repo]) via git clone.

## Configuration
Change into vipeval root directory. Edit `config/appcfg.yml` (see explanations
in config file). Normally you should only edit under `ecs:`.

## Running
### Running in foreground
Change into vipeval root directory and type:

    bundle exec rails console -e production

In the upcoming irb (interactive ruby shell) type:

    MainLoop.instance.start

### Running in background
For instance via rails runner, change into vipeval root directory and type:

    bundle exec rails runner -e production MainLoop.instance.start &

or

    /path/to/vipeval/bundle exec rails runner -e production MainLoop.instance.start &

You can place this also in a startup script (e.g. [sles12 init
script][vipeval-sles12-startscript]):

    ...
    case "$1" in
        start)
            echo -n "Starting VIP Evaluation Backend"
            su -l -c "cd $VIPEVAL_ROOT && bundle exec rails runner -e production MainLoop.instance.start &" freeit
            rc_status -v
            ;;
        stop)
    ...

### Providing ECS basic auth credentials via environment variables
For security reasons you may want to serve at least the ECS login password
via shell environment variable. Therefore you must uncomment the
`#password: <%= ENV['ECS_PASSWORD'] %>` line in `config/appcfg.yml` and
comment the old `password: ...` line. Then you can provide the password as
an environment variable at the command line:

    ECS_PASSWORD=my-secure-password bundle exec rails console -e production

or

    ECS_PASSWORD=my-secure-password bundle exec rails runner -e production MainLoop.instance.start &

Of course it's up to you how you set the ECS\_PASSWORD enverionment
variable. For instance you set it in your startup script (e.g. [sles12 init
script][vipeval-sles12-startscript]), which is owned by root and could
only read by him. Or read it from a file owned and readable by root:

    ECS_PASSWORD=$(cat my_password_file) bundle exec ...

[vipeval-master_freeit.tgz]: https://git.freeit.de/vipeval/snapshot/vipeval-master.tar.gz
[vipeval-master_github.zip]: https://github.com/freeit/vip_evaluation_server/archive/master.zip
[freeit-repo]: https://git.freeit.de/vipeval
[github-repo]: https://github.com/freeit/vip_evaluation_server
[vipeval-sles12-startscript]: misc/vipeval_sles12_startscript
