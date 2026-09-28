class KubevirtEventCatcher < KubernetesEventCatcherBase
  ENABLED_EVENTS = KubevirtEventParser::ENABLED_EVENTS

  def filtered?(event_data)
    supported_reasons = ENABLED_EVENTS[event_data[:kind]] || []
    !supported_reasons.include?(event_data[:reason]) || filtered_events.include?(event_data[:event_type])
  end

  private

  def log_prefix
    'MIQ(ManageIQ::Providers::Kubevirt::InfraManager::EventCatcher)'
  end
end
