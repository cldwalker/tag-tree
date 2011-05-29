require ::File.expand_path('application')
run lambda {|e| [200, {'Content-Type' => 'text/html'}, ['hello']] }
