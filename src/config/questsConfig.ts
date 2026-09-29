import { CustomClient } from "../core/customClient.js";

export default {
    notification: {
        token: "--" ,
        channel: "1414963290391707779",
        role: "1405572212403994684",
        dm: {
            enabled: true,
            dmRoles: ["1405572212403994684"],
        }

    },
    bypassLimit: ["1423422187372544081"],
    durationQuests: [
        "WATCH_VIDEO",
        "PLAY_ON_DESKTOP",
        "STREAM_ON_DESKTOP",
        "PLAY_ACTIVITY",
        "WATCH_VIDEO_ON_MOBILE",
        "PLAY_ON_XBOX",
        "PLAY_ON_PLAYSTATION"
    ],

    image: {
        channelId: "1421221274721456242",
        guildId: "1399471603003428966",
    },
    serverId: "1399471603003428966",
    completedQuestsChannel: "1414963290391707779",
    voice: {
        channel: "1421938834651742270",
        role: "1405572212403994684"
    },


    logStrings: [],
    childProcessCount: 1,
    questsPerChildProcess: 15,
    useProxy: true,
    proxyType: "http",
    buttons: [
        {
            url: "https://youtu.be/eJoa4obHhng",
            emoji: (e:CustomClient) => e.getEmoji("youtube",false) ?? "▶️",
        }
    ],






    customRewardsImage: {
        "1298745361602449479": "https://i.ibb.co/rRNztwKq/reward.webp",
        "1287881739531976815": "https://i.ibb.co/vxTHNqsS/eff35518172b971fa47c521ca21c7576d3a245433a669a6765f63b744b7b733a.png"
    },
    customRewardsEmoji: {
        "1287881739531976815": "orbIcon",
        "1298745361602449479": "nitro_level_stone"
    },
    inviteUrl: "https://discord.gg/kZHHmhKE",
    joinMessage: `## انت مو داخل السيرفر
    - **عشان تستعمل البوت لازم تدخل السيرفر ب الحساب الي تبي تسوي فيه المهمة**
    - **ملاحظة البوت مجاني 100%**
    
    ## You are not in the server
    - **To use the bot, you need to join the server with the account you want to complete the task with.**
    - **Note: The bot is 100% free.**
    
    - ** https://discord.gg/39c2c3jVbN **`
}