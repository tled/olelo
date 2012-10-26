description 'Filter which converts remind calendars to html'

Filter.create :remind do |context, content|
  unless context.params[:date]
    throw :redirect, build_path(context.page.path,
                                context.request.params.merge(date: Time.now.strftime('%Y-%m')))
  end
  months = (context.params[:months] || 2).to_i
  date = context.params[:date].split('-', 2)
  date = Time.new(date.first.to_i, date.last.to_i).strftime('%Y/%m/01')
  Shell.new.
    remind('-m', '-p', "-c#{months}", '-', date).
    perl(File.join(File.dirname(__FILE__), 'rem2html'), '--tableonly').
    run(content)
end
