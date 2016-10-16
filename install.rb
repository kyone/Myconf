#!/usr/bin/ruby

require 'fileutils'
require 'optparse'

class Main
    def initialize(args)
        @options = { :yes => false }

        optparser = OptionParser.new do |opts|
            opts.on("-f", "--force", "overwrite exisiting files") do |pass|
                @options[:force] = pass
            end

            opts.on("-u", "--undo", "delete created files") do |pass|
                @options[:undo] = pass
            end

            opts.on("-s", "--sync", "read preferences of current user and copy in `Configuration` folder") do |pass|
                @options[:sync] = pass
            end

            opts.on("-y", "--yes", "answer yes to everything") do |pass|
                @options[:sync] = pass
            end
        end

        begin
            optparser.parse! args
        rescue OptionParser::InvalidOption => e
            $stderr.puts e.to_s
            $stderr.puts optparser.help
            exit 1
        end

        @configuration = [
            { :description => "macOS preferences (eg: Finder, Dock, etc.)", :conf => "Configuration/Preferences", :path => "~/Library/Preferences" },
            { :description => "Sublime Text 3 configuration", :conf => "Configuration/ST3", :path => "~/Library/Application Support/Sublime Text 3" },
            { :description => "Terminal configuration", :conf => "Configuration/Terminal", :path => "~", :post_flight => lambda { |file| FileUtils.mv(file, File.join(File.dirname(file), ".#{File.basename(file)}")) if File.exist?(file) } },
            { :description => "Xcode configuration", :conf => "Configuration/Xcode", :path => "~/Library/Developer/Xcode/UserData" },
            { :description => "AndroidStudio configuration", :conf => "Configuration/AndroidStudio", :path => "~/Library/Preferences/AndroidStudio1.5" },
        ]
    end
    
    def askToExecute(question, code)
        if !@options[:yes]
            puts "#{question}? [yN]"
            a = gets.chomp.downcase
            if a == "y" || a == "yes" || a == "yep"
                yield code
            end
        else
            yield code
        end
    end

    def run()
        @configuration.each do |conf|
            question = "Install #{conf[:description]}"
            if @options[:undo]
                question = "Remove #{conf[:description]}"
            elsif @options[:sync]
                question = "Copy current system's \"#{conf[:description]}\" into `Configuration` folder}"
            end

            code = lambda { |conf|
                Dir.glob(File.join(conf[:conf], "**/**")) do |file|
                    output = File.join(conf[:path], file[conf[:conf].length, file.length - conf[:conf].length])

                    file = File.expand_path(file)
                    output = File.expand_path(output)

                    if @options[:undo]
                        if File.file?(output)
                            FileUtils.rm_f(output)
                        end
                    elsif @options[:sync]
                        if File.file?(output)
                            FileUtils.cp(output, file, { :verbose => true })
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
            }

            askToExecute(question, code)

        end
    end

end

main = Main.new(ARGV)
main.run()