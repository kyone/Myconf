#!/usr/bin/ruby

require 'fileutils'
require 'optparse'

class Main
    def initialize(args)
        @options = {}

        optparser = OptionParser.new do |opts|
            opts.on("-f", "--force", "overwrite exisiting files") do |pass|
                @options[:force] = pass
            end

            opts.on("-u", "--undo", "delete created files") do |pass|
                @options[:undo] = pass
            end
        end

        optparser.parse!

        @configuration = [
            { :conf => "Configuration/Preferences", :path => "~/Library/Preferences" },
            { :conf => "Configuration/ST3", :path => "~/Library/Application Support/Sublime Text 3" },
            { :conf => "Configuration/Terminal", :path => "~", :post_flight => lambda { |file| FileUtils.mv(file, File.join(File.dirname(file), ".#{File.basename(file)}")) if File.exist?(file) } },
            { :conf => "Configuration/Xcode", :path => "~/Library/Developer/Xcode/UserData" },
            { :conf => "Configuration/AndroidStudio", :path => "~/Library/Preferences/AndroidStudio1.5" },
        ]
    end
    
    def run()
        @configuration.each do |conf|
            Dir.glob(File.join(conf[:conf], "**/**")) do |file|
                output = File.join(conf[:path], file[conf[:conf].length, file.length - conf[:conf].length])

                file = File.expand_path(file)
                output = File.expand_path(output)

                if @options[:undo]
                    if File.file?(output)
                        puts "Remove #{output}"
                        FileUtils.rm_f(output)
                    end
                else
                    if File.directory?(output)
                        puts "#{output} already exists"
                        next
                    end

                    if File.file?(output)
                        if @options[:force]
                            File.unlink(output)
                        else
                            puts "#{output} already exists"
                            next
                        end
                    end

                    if File.directory?(File.dirname(output)) == false
                        FileUtils.mkdir_p(File.dirname(output))
                    end

                    FileUtils.cp_r(file, output, { :verbose => true })

                    if conf[:post_flight] != nil
                        conf[:post_flight].call(output)
                    end
                end
            end
        end
    end

end


main = Main.new(ARGV)
main.run()