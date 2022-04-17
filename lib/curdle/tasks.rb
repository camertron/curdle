module Curdle
  module Tasks
    class << self
      include Rake::DSL

      def install(gemspec_file = find_gemspec)
        task :build do
          require 'tmpdir'
          require 'fileutils'

          Dir.mktmpdir do |build_dir|
            spec = Bundler.load_gemspec(gemspec_file)

            spec.files.each do |source_path|
              next if File.directory?(source_path)

              dest_path = File.join(build_dir, source_path)
              FileUtils.mkdir_p(File.dirname(dest_path))

              if File.extname(source_path) == '.rb'
                File.write(dest_path, Curdle.process(File.read(source_path)))
              else
                FileUtils.cp(source_path, dest_path)
              end
            end

            system("gem build --silent -C #{build_dir}")
            artifact = Dir.glob(File.join(build_dir, "#{spec.name}*.gem")).first

            FileUtils.mkdir_p('pkg')
            artifact_dest = File.join('pkg', File.basename(artifact))
            FileUtils.cp(artifact, artifact_dest)

            puts "#{spec.name} #{spec.version} built to #{artifact_dest}."
          end
        end
      end

      private

      def find_gemspec
        Dir.glob(File.join(Dir.getwd, '*.gemspec')).first
      end
    end
  end
end