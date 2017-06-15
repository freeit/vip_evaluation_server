require 'zip'

class JobEvent

  include VipPack

  def initialize
    @ecs=HttpEcs.instance
  end

  ##
  # Process a *sys/events* job event.
  # This is the entrypoint of job event processing.
  def process(jobevbody)
    Rails.logger.debug "***** JobEvent#process: eventbody=#{jobevbody}"
    case jobevbody[0]['status']
    when "created","updated"
      jobr= @ecs.connection[jobevbody[0]['ressource']].delete
      job_headers= jobr.headers
      job=JSON.parse(jobr)
      Rails.logger.debug "***** JobEvent#process: EvaluationJob: #{JSON.pretty_generate(job)}"
      exercise = JSON.parse fetch_exercise(job)
      evaluation = JSON.parse fetch_evaluation(job)
      solution = JSON.parse fetch_solution(job)
      exercise,solution = merge(exercise, evaluation, solution, job, job_headers)
      computation_backend = job["EvaluationJob"]["target"]["mid"]
      compute(exercise, solution, computation_backend)
    end
  end

  private

  ##
  # Fetch an exercise from ECS.
  def fetch_exercise(job)
    # URI#path returns the path with leading "/"
    /#{APP_CONFIG["resources"]["exercises"]["name"]}.*$/ =~ URI(job["EvaluationJob"]["resources"]["exercise"]).path[1..-1]
    path = $~.to_s
    Rails.logger.debug "***** JobEvent#fetch_exercise: exercise path #{path}"
    exercise= @ecs.connection[path].delete
    exercise = unpack(exercise.body) if packed?(exercise.body)
    Rails.logger.debug "***** JobEvent#fetch_exercise: #{path} = #{exercise}"
    exercise
  end

  ##
  # Fetch an evaluation from ECS.
  def fetch_evaluation(job)
    # URI#path returns the path with leading "/"
    /#{APP_CONFIG["resources"]["evaluations"]["name"]}.*$/ =~ URI(job["EvaluationJob"]["resources"]["evaluation"]).path[1..-1]
    path = $~.to_s
    evaluation= @ecs.connection[path].delete
    evaluation = unpack(evaluation.body) if packed?(evaluation.body)
    Rails.logger.debug "***** JobEvent#fetch_evaluation: #{path} = #{evaluation}"
    evaluation
  end

  ##
  # Fetch a solution from ECS.
  def fetch_solution(job)
    # URI#path returns the path with leading "/"
    /#{APP_CONFIG["resources"]["solutions"]["name"]}.*$/ =~ URI(job["EvaluationJob"]["resources"]["solution"]).path[1..-1]
    path = $~.to_s
    solution= @ecs.connection[path].delete
    solution = unpack(solution.body) if packed?(solution.body)
    Rails.logger.debug "***** JobEvent#fetch_solution: #{path} = #{solution}"
    solution
  end

  ##
  # Substitute evaluation code snippets with appropriate exercise code
  # snippets.
  def merge(exercise, evaluation, solution, job, job_headers)
    jobid= job["EvaluationJob"]["identifier"]
    job_sender= job_headers[:x_ecssender]
    evaluation["Evaluation"]["elements"].each do |ev|
      exercise["Exercise"]["elements"].map! do |ex|
        if ex["identifier"] == ev["identifier"]
          ex=ev
        else
            ex
        end
      end
    end
    solution["Solution"]["evaluationService"]= { :jobID => jobid, :jobSender => job_sender }
    Rails.logger.debug "***** JobEvent#merge exercise: #{exercise.to_json}"
    Rails.logger.debug "***** JobEvent#merge solution: #{solution.to_json}"
    return exercise, solution
  end

  ##
  # Calls the computation backend with membership_id *mid*.
  def compute(exercise, solution, mid)
    response= @ecs.connection[APP_CONFIG["resources"]["exercises"]["name"]].post exercise.to_json, {"X-EcsReceiverMemberships" => mid}
    solution["Solution"]["exercise"]= response.headers[:location]
    Rails.logger.debug "***** JobEvent#compute substitute exersice URL in solution to: #{solution["Solution"]["exercise"]}"
    if exercise["Exercise"]["routing"]
      routing_path = APP_CONFIG["resources"]["servicename"]+"/"+exercise["Exercise"]["routing"]["solutionQueue"]
    else
      routing_path = APP_CONFIG["resources"]["solutions"]["name"]
    end
    Rails.logger.debug "***** JobEvent#compute routing path for solution: #{routing_path}"
    @ecs.connection[routing_path].post solution.to_json, {"X-EcsReceiverMemberships" => mid} do |response, request, result|
      Rails.logger.debug "***** JobEvent#compute solution post response: #{response.headers}"
    end
  end

end
