# Based on the examples available at https://github.com/ansible/ansible/tree/devel/plugins/callbacks
# and the similar https://github.com/ginsys/ansible-plugins/blob/devel/callback_plugins/timestamp.py

# imports
import time
from ansible.callbacks import display

# define start time
t0 = tn = time_play_start = time.time()

def secondsToStr(t):

    # http://bytes.com/topic/python/answers/635958-handy-short-cut-formatting-elapsed-time-floating-point-seconds
    rediv = lambda ll,b : list(divmod(ll[0],b)) + ll[1:]
    return "%d:%02d:%02d.%03d" % tuple(reduce(rediv,[[t*1000,], 1000,60,60]))

def filled(msg, fchar="*"):

    if len(msg) == 0:
        width = 79
    else:
        msg = "%s " % msg
        width = 79 - len(msg)
    if width < 3:
        width = 3
    filler = fchar * width
    return "%s%s " % (msg, filler)

def timestamp(type="task"):

    global tn, time_play_start
    time_elapsed = secondsToStr(time.time() - tn)
    time_play_elapsed = secondsToStr(time.time() - time_play_start)
    time_total_elapsed = secondsToStr(time.time() - t0)

    display( filled( 'Previous Task Duration: %s   Overall Duration: %s' % (time_elapsed, time_total_elapsed )))
    if type == "play":
        display( filled( 'Previous Play Duration: %s' % (time_play_elapsed )))

    tn = time.time()


class CallbackModule(object):

    def playbook_on_setup(self):
        timestamp()
        pass

    def playbook_on_play_start(self, pattern):
        global time_play_start
        timestamp(type="play")
        time_play_start = time.time()
        pass

    def playbook_on_stats(self, stats):
        timestamp(type="play")
        pass
