#!/bin/sh
# chkconfig: 345 99 55
# description: script to start kewatcher
# /etc/init.d/[application]_kewatcher

# source functions library
. /etc/rc.d/init.d/functions

# source application params
. /etc/sysconfig/deployed_application

start() {
  local program
  local options

  if [ -e $KEWATCHER_PIDFILE ] && kill -0 `cat $KEWATCHER_PIDFILE` > /dev/null 2>&1; then
    echo "KEWatcher is already Running"
    return 0
  fi

  cd $ROOT_PATH

  env_vars="RAILS_ENV=$RAILS_ENV"
  options="-m $KEWATCHER_MAX_WORKERS -c $KEWATCHER_REDIS_CONFIG -p $KEWATCHER_PIDFILE $KEWATCHER_VERBOSE"
  program="source /home/$APP_USER/.bash_profile; $env_vars bundle exec $ROOT_PATH/bin/kewatcher $options 2>&1 >> $KEWATCHER_LOGFILE &"

  action 'Starting KEWatcher...' daemon --user "${APP_USER#$USER}" --pidfile=$KEWATCHER_PIDFILE $program

  # workaround to allow KEWatcher to setup a trap for HUP signal
  sleep 5
}

stop() {
  if [ -f $KEWATCHER_PIDFILE ]; then
    # The idea is to let KEWatcher to gracefully stop,
    # wait with delay gives us dynamic wait interval
    # limited by N tries.

    action 'Stopping KEWatcher...' _stop_with_wait $(cat $KEWATCHER_PIDFILE)
  else
    echo "Resque KEWatcher is not running"
  fi

  echo 'Killing stuck workers...'
  kill -s KILL `pgrep -xf "[r]esque-[0-9]+.*" | xargs` > /dev/null 2>&1

  rm -f $KEWATCHER_PIDFILE
}

_stop_with_wait() {
  local pid delay tries try

  delay=10
  tries=3
  pid=$1
  try=0

  kill -s QUIT $pid

  while [ $try -lt $tries ] ; do
    checkpid $pid || return 0
    sleep $delay
    let try+=1
  done
}

case "$1" in
  start) start ;;
  stop) stop ;;
  restart)
    echo "Restarting Resque KEWatcher..."
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit $?
