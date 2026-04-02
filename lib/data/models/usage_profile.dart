enum UsageProfile { idleOffice, balanced, gaming, renderAi }

extension UsageProfileX on UsageProfile {
  String get storageKey {
    switch (this) {
      case UsageProfile.idleOffice:
        return 'idle_office';
      case UsageProfile.balanced:
        return 'balanced';
      case UsageProfile.gaming:
        return 'gaming';
      case UsageProfile.renderAi:
        return 'render_ai';
    }
  }

  String get label {
    switch (this) {
      case UsageProfile.idleOffice:
        return 'Idle / Office';
      case UsageProfile.balanced:
        return 'Balanced';
      case UsageProfile.gaming:
        return 'Gaming';
      case UsageProfile.renderAi:
        return 'Render / AI';
    }
  }

  String get shortLabel {
    switch (this) {
      case UsageProfile.idleOffice:
        return 'Office';
      case UsageProfile.balanced:
        return 'Balanced';
      case UsageProfile.gaming:
        return 'Gaming';
      case UsageProfile.renderAi:
        return 'Render/AI';
    }
  }

  String get description {
    switch (this) {
      case UsageProfile.idleOffice:
        return 'Lower CPU and GPU activity for browsing, school, and office work.';
      case UsageProfile.balanced:
        return 'A mixed everyday profile for normal desktop use and occasional heavy tasks.';
      case UsageProfile.gaming:
        return 'Higher GPU activity with elevated cooling and platform overhead.';
      case UsageProfile.renderAi:
        return 'Sustained CPU and GPU load for exports, rendering, or local AI work.';
    }
  }
}

UsageProfile usageProfileFromStorage(String? raw) {
  for (final profile in UsageProfile.values) {
    if (profile.storageKey == raw) {
      return profile;
    }
  }
  return UsageProfile.balanced;
}
