import time
from slackclient import SlackClient
import subprocess

BOT_TOKEN = "xoxb-251353056034-n4LZ4inSYXpajuyVBU9hNSKl"
CHANNEL_NAME = "general"

def main():
    # Create the slackclient instance
    sc = SlackClient(BOT_TOKEN)

    # Connect to slack
    if sc.rtm_connect():
        # Send first message
        sc.rtm_send_message(CHANNEL_NAME, "I'm ALIVE!!!")

        while True:
            # Read latest messages
            for slack_message in sc.rtm_read():
                message = slack_message.get("text")
                user = slack_message.get("user")
                
                if not message or not user:
                    continue

                # import ipdb; ipdb.set_trace()

                if message == 'deploy':
                    output = subprocess.Popen(['nohup', '/Users/julia/bot/test.sh'], stdout=subprocess.PIPE).communicate()[0]
                    sc.rtm_send_message(CHANNEL_NAME, "<@{}> You wrote {}. Response: {}".format(user, message, output))

            # Sleep for half a second
            time.sleep(0.5)
    else:
        print("Couldn't connect to slack")

if __name__ == '__main__':
    main()