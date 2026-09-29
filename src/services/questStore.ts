export type QuestId = "messages" | "voice";

export interface Progress {
  messages: number;
  voiceMinutes: number;
  claimed: Set<QuestId>;
  voiceStartedAt?: number;
}

class QuestStore {
  private readonly progress = new Map<string, Progress>();

  get(guildId: string, userId: string): Progress {
    const key = `${guildId}:${userId}`;
    let value = this.progress.get(key);
    if (!value) {
      value = { messages: 0, voiceMinutes: 0, claimed: new Set<QuestId>() };
      this.progress.set(key, value);
    }
    return value;
  }

  addMessage(guildId: string, userId: string): void {
    this.get(guildId, userId).messages += 1;
  }

  startVoice(guildId: string, userId: string): void {
    this.get(guildId, userId).voiceStartedAt = Date.now();
  }

  endVoice(guildId: string, userId: string): void {
    const progress = this.get(guildId, userId);
    if (!progress.voiceStartedAt) return;
    progress.voiceMinutes += Math.floor((Date.now() - progress.voiceStartedAt) / 60000);
    delete progress.voiceStartedAt;
  }
}

export const questStore = new QuestStore();
