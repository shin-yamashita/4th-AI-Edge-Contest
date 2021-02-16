#!/usr/bin/env ruby

print "  --   "
for b in 40..47
  s = b.to_s
  print "\033[", s, "m    ", s, "   \033[0m "
end
print "\n"
for c in [ 30, 31, 32, 33, 34, 35, 36, 37, 90, 91, 92, 93, 94, 95, 96, 97 ]
  s = c.to_s
  print "\033[", s, "m ", s, "   \033[0m "
  for b in 40..47
    s = c.to_s + ";" + b.to_s
    print "\033[", s, "m ", s, "   \033[0m "
  end
  print "\n"
  for a in [ 1, 4 ]
    s = c.to_s + ";" + a.to_s
    print "\033[", s, "m ", s, " \033[0m "
    for b in 40..47
      s = c.to_s + ";" + b.to_s + ";" + a.to_s
      print "\033[", s, "m ", s, " \033[0m "
    end
    print "\n"
  end
end

