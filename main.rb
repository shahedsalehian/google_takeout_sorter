require 'json'
require 'date'
require 'fileutils'
require 'pp'
require 'set'

extensions = Set[
 "mp4",
 "3gp",
 "jpg",
 "JPG",
 "png",
 "PNG",
 "mov",
 "MOV",
 "heic",
 "HEIC",
 "gif",
 "GIF",
 "jpeg",
 "JPEG"
]

default_path = "Takeout/Google\ Photos"

if File.exist?(default_path)
  input_folder = default_path
  print "Default extraction folder ./Takeout/Google Photos/ found. Using it as input folder.\n"
else
  print "Relative path to EXTRACTED google takeout folder: "
  input_folder = gets.chomp
end

print "Relative path to output folder: "
output_folder = gets.chomp

print "Creating output folder...\n"
begin
  FileUtils.mkdir_p("./#{output_folder}")
rescue Exception => e
  raise e
else
  print "Successfully created output folder\n"
end

print "Do you wish to start?[Y/N]" 
start = gets.chomp
exit unless start.downcase == "y"

print "Processing Takeout folder...\n"
Dir.each_child(input_folder) do |photo_dir|
  next if /.json/.match?(photo_dir)
  Dir.each_child("#{input_folder}/#{photo_dir}") do |file|
    if /.json/.match?(file)
      json = JSON.parse(File.read("#{input_folder}/#{photo_dir}/#{file}"))
      next unless json['title']
      source_path = "#{Dir.pwd}/#{input_folder}/#{photo_dir}/#{json['title']}"

      date = DateTime.parse(json['photoTakenTime']['formatted'])
      month = date.strftime("%m").downcase
      year = date.strftime("%Y").downcase
      target_path = "#{Dir.pwd}/#{output_folder}/#{year}/#{month}/#{json['title']}"
      target_dir = "#{Dir.pwd}/#{output_folder}/#{year}/#{month}"
      FileUtils.mkdir_p(target_dir)
      if File.exist?(source_path)
        begin
          FileUtils.mv(source_path, target_path)
        rescue Exception => e
          raise e
        else
          FileUtils.rm("#{Dir.pwd}/#{input_folder}/#{photo_dir}/#{file}")
        end
      else
        for extension in extensions do
          split_source_path = source_path.split(".")
          split_source_path[-1] = extension
          source_path = split_source_path.join(".")

          if File.exist?(source_path)
            begin
              FileUtils.mv(source_path, target_path)
            rescue Exception => e
              raise e
            else
              FileUtils.rm("#{Dir.pwd}/#{input_folder}/#{photo_dir}/#{file}")
              break
            end
          end
        end
      end
    end
  end
end
print "Successfully processed takeout folder\n"

print "Do you wish to move all unsortable files to an unsorted folder? [Y/N]"
start = gets.chomp
exit unless start.downcase == "y"
print "Creating unsorted folder...\n"
begin
  FileUtils.mkdir_p("./#{output_folder}/unsorted")
rescue Exception => e
  raise e
else
  print "Successfully created unsorted folder\n"
end

print "Processing unsortable files...\n"
Dir.each_child(input_folder) do |photo_dir|
  next if /.json/.match(photo_dir)
  Dir.each_child("#{input_folder}/#{photo_dir}") do |file|
    FileUtils.mv("#{input_folder}/#{photo_dir}/#{file}", "#{output_folder}/unsorted/#{file}", verbose: true) unless /.json/.match(file)
  end
end

print "Successfully processed all unsortable files\n"
