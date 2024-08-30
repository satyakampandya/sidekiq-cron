module Sidekiq
  module Cron
    module WebExtension
      def self.registered(app)
        app.settings.locales << File.join(File.expand_path("..", __FILE__), "locales")

        # Index page of cron jobs.
        app.get '/cron' do
          view_path    = File.join(File.expand_path("..", __FILE__), "views")

          @page = params[:page].to_i
          @page = 1 if @page < 1

          @per_page = params[:per_page].to_i
          @per_page = 25 if @per_page < 1

          starting_index = (@page - 1) * @per_page
          ending_index = starting_index + @per_page - 1

          @total_size = Sidekiq::Cron::Job.count
          @cron_jobs = Sidekiq::Cron::Job.all(offset: starting_index, limit: ending_index)

          render(:erb, File.read(File.join(view_path, "cron.erb")))
        end

        # Display job detail + jid history.
        app.get '/cron/:name' do
          view_path = File.join(File.expand_path("..", __FILE__), "views")

          @job = Sidekiq::Cron::Job.find(route_params[:name])
          if @job
            render(:erb, File.read(File.join(view_path, "cron_show.erb")))
          else
            redirect "#{root_path}cron"
          end
        end

        # Enqueue cron job.
        app.post '/cron/:name/enque' do
          if route_params[:name] === '__all__'
            Sidekiq::Cron::Job.all.each(&:enque!)
          elsif job = Sidekiq::Cron::Job.find(route_params[:name])
            job.enque!
          end
          redirect params['redirect'] || "#{root_path}cron"
        end

        # Delete schedule.
        app.post '/cron/:name/delete' do
          if route_params[:name] === '__all__'
            Sidekiq::Cron::Job.all.each(&:destroy)
          elsif job = Sidekiq::Cron::Job.find(route_params[:name])
            job.destroy
          end
          redirect "#{root_path}cron"
        end

        # Enable job.
        app.post '/cron/:name/enable' do
          if route_params[:name] === '__all__'
            Sidekiq::Cron::Job.all.each(&:enable!)
          elsif job = Sidekiq::Cron::Job.find(route_params[:name])
            job.enable!
          end
          redirect params['redirect'] || "#{root_path}cron"
        end

        # Disable job.
        app.post '/cron/:name/disable' do
          if route_params[:name] === '__all__'
            Sidekiq::Cron::Job.all.each(&:disable!)
          elsif job = Sidekiq::Cron::Job.find(route_params[:name])
            job.disable!
          end
          redirect params['redirect'] || "#{root_path}cron"
        end
      end
    end
  end
end
