module ApplicationHelper
  FILTER_CONTROL_CLASS = "h-11 rounded border border-border bg-surface px-3 text-sm text-text " \
                         "focus:outline-none focus:ring-2 focus:ring-accent".freeze
  CREATE_BUTTON_CLASS = "flex h-11 items-center rounded border-0 bg-accent px-5 text-sm font-semibold " \
                        "text-accent-contrast".freeze
  NAV_ENTRY_CLASS = "rounded px-3 py-2 text-sm font-medium".freeze

  # Shared styling for index filter bar inputs and selects.
  def filter_control_class
    FILTER_CONTROL_CLASS
  end

  # Shared styling for an index page's primary "create" button.
  def create_button_class
    CREATE_BUTTON_CLASS
  end

  # Styling for a top-level sidebar entry, highlighted when it matches the current section.
  def nav_entry_class(active)
    "#{NAV_ENTRY_CLASS} #{active ? "bg-white/5 text-accent" : "text-sidebar-text hover:bg-white/5"}"
  end

  def nav_active?(*controller_names)
    controller_names.include?(controller.controller_name)
  end
end
