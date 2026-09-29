import type { Client } from "discord.js";
import { questStore } from "../services/questStore.js";
import { logger } from "../utils/logger.js";

export function registerEvents(client: Client): void {
  client.once("ready", (readyClient) => {
    logger.info(`Logged in as ${readyClient.user.tag}`);
  });

  client.on("messageCreate", (message) => {
    if (message.author.bot || !message.guild) return;
    questStore.addMessage(message.guild.id, message.author.id);
  });

  client.on("voiceStateUpdate", (oldState, newState) => {
    if (oldState.member?.user.bot || newState.member?.user.bot) return;
    const guildId = newState.guild.id;
    const userId = newState.id;

    if (!oldState.channelId && newState.channelId) {
      questStore.startVoice(guildId, userId);
    } else if (oldState.channelId && !newState.channelId) {
      questStore.endVoice(guildId, userId);
    }
  });
}
