class JobEvent
  def initialize
    @ecs=HttpEcs.instance
  end

  ##
  # Process a *sys/events* job event.
  # This is the entrypoint of job event processing.
  def process(jobev)
    Rails.logger.info "***** JobEvent#process: eventbody=#{jobev}"
    case jobev[0]['status']
    when "created","updated"
      job=JSON.parse(@ecs.connection[jobev[0]['ressource']].delete)
      exercise = JSON.parse fetch_exercise(job)
      evaluation = JSON.parse fetch_evaluation(job)
      solution = JSON.parse fetch_solution(job)
      exercise,solution = merge(exercise, evaluation, solution, job["EvaluationJob"]["identifier"])
      computation_backend = job["EvaluationJob"]["target"]["mid"]
      compute(exercise, solution, computation_backend)
    end
  end

  private

  ##
  # Fetch an exercise from ECS.
  def fetch_exercise(job)
    # URI#path returns the path with leading "/"
    path= URI(job["EvaluationJob"]["resources"]["exercise"]).path[1..-1]
    exercise= @ecs.connection[path].get # FIXME change to delete
    Rails.logger.info "***** JobEvent#fetch_exercise: #{path} = #{exercise}"
    exercise
  end

  ##
  # Fetch an evaluation from ECS.
  def fetch_evaluation(job)
    # URI#path returns the path with leading "/"
    path= URI(job["EvaluationJob"]["resources"]["evaluation"]).path[1..-1]
    evaluation= @ecs.connection[path].get # FIXME change to delete
    Rails.logger.info "***** JobEvent#fetch_evaluation: #{path} = #{evaluation}"
    evaluation
  end

  ##
  # Fetch a solution from ECS.
  def fetch_solution(job)
    # URI#path returns the path with leading "/"
    path= URI(job["EvaluationJob"]["resources"]["solution"]).path[1..-1]
    solution= @ecs.connection[path].get # FIXME change to delete
    Rails.logger.info "***** JobEvent#fetch_solution: #{path} = #{solution}"
    solution
  end

  ##
  # Substitute evaluation code snippets with appropriate exercise code
  # snippets.
  def merge(exercise, evaluation, solution, jobid)
    evaluation["Evaluation"]["elements"].each do |ev|
      exercise["Exercise"]["elements"].map! do |ex|
        if ex["identifier"] == ev["identifier"]
          ex=ev
        else
            ex
        end
      end
    end
    solution["Solution"]["evaluationJobID"]= jobid
    Rails.logger.info "***** JobEvent#merge exercise: #{exercise.to_json}"
    Rails.logger.info "***** JobEvent#merge solution: #{solution.to_json}"
    return exercise, solution
  end

  ##
  # Calls the computation backend with membership_id *mid*.
  def compute(exercise, solution, mid)
    @ecs.connection[APP_CONFIG["resources"]["exercises"]["name"]].post exercise.to_json, {"X-EcsReceiverMemberships" => mid}
    @ecs.connection[APP_CONFIG["resources"]["solutions"]["name"]].post solution.to_json, {"X-EcsReceiverMemberships" => mid}
  end

end
