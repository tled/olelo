description  'Scripting tags'
dependencies 'filter/tag'
require      'evaluator'

Tag.define :value, :requires => :of, :immediate => true, :description => 'Print value' do |context, attrs|
  Evaluator.eval(attrs['of'], context.params)
end

Tag.define :def, :optional => %w(value args), :requires => :name,
                 :immediate => true, :description => 'Define variable' do |context, attrs, content|
  name = attrs['name'].downcase
  if attrs['value']
    context.params[name] = Evaluator.eval(attrs['value'], context.params)
  else
    functions = context[:functions] ||= {}
    functions[name] = [attrs['args'].to_s.split(/\s+/), content]
  end
  nil
end

Tag.define :call, :optional => '*', :requires => :name, :immediate => true, :description => 'Call function' do |context, attrs|
  name = attrs['name'].downcase
  functions = context[:functions]
  raise NameError, "Function #{name} not found" if !functions || !functions[name]
  args, content = functions[name]
  args = args.inject({}) do |hash, arg|
    raise ArgumentError, "Argument #{arg} is required" if !attrs[arg]
    hash[arg] = Evaluator.eval(attrs[arg], context.params)
    hash
  end
  result = nested_tags(context.subcontext(:params => args), content)
  if attrs['result']
    context.params[attrs['result']] = result
    nil
  else
    result
  end
end

Tag.define :for, :optional => :counter, :requires => %w(from to),
                 :immediate => true, :limit => 50, :description => 'For loop' do |context, attrs, content|
  to = attrs['to'].to_i
  from = attrs['from'].to_i
  raise 'Limits exceeded' if to - from > 10
  (from..to).map do |i|
    params = attrs['counter'] ? {attrs['counter'] => i} : {}
    nested_tags(context.subcontext(:params => params), content)
  end.join
end

Tag.define :repeat, :optional => :counter, :requires => :times,
           :immediate => true, :limit => 50, :description => 'Repeat loop' do |context, attrs, content|
  n = attrs['times'].to_i
  raise 'Limits exceeded' if n > 10
  (1..n).map do |i|
    params = attrs['counter'] ? {attrs['counter'] => i} : {}
    nested_tags(context.subcontext(:params => params), content)
  end.join
end

Tag.define :if, :requires => :test, :immediate => true, :description => 'If statement' do |context, attrs, content|
  if Evaluator.eval(attrs['test'], context.params)
    nested_tags(context.subcontext, content)
  end
end
