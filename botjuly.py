import time
from slackclient import SlackClient
import subprocess 
from subprocess import call
cmd = './check.sh'
BOT_TOKEN = "xoxb-251353056034-8naDytRqvE4Hjm3y9WD7Wje0"
CHANNEL_NAME = "general"

def main():
    # Create the slackclient instance
    sc = SlackClient(BOT_TOKEN)

    # Connect to slack
    if sc.rtm_connect():
        # Send first message
        sc.rtm_send_message(CHANNEL_NAME, "I'm ALIVE!!!")

        #deploy_in_progress = False

        while True:
            # Read latest messages
            for slack_message in sc.rtm_read():
                message = slack_message.get("text")
                user = slack_message.get("user")
                
                if not message or not user:
                    continue

                # import ipdb; ipdb.set_trace()

                if message == 'd':
                    #deploy_in_progress = True
                    #output = subprocess.Popen(['nohup', '/Users/julia/bot/test.sh'], stdout=subprocess.PIPE).communicate()[0]
                    output = call(cmd, shell=True)
                    import ipdb; ipdb.set_trace()
                    if output == 1:
                        sc.rtm_send_message(CHANNEL_NAME, "<@{}> DEU ERRO MALANDRAGE! ".format(user))
                    else:
                        sc.rtm_send_message(CHANNEL_NAME, "<@{}> Checagem feita com sucesso. Tudo ok. Voce tem certeza que deseja realuzar o deploy? ".format(user))

                #if message == 'y' and deploy_in_progress
                    # executa o segundo script

            # Sleep for half a second
        time.sleep(0.5)
    else:
        print("Couldn't connect to slack")

if __name__ == '__main__':
    main()
