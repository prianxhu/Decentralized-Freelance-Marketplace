// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DecentralizedFreelanceMarketplace {
    enum JobStatus { Open, InProgress, Completed }

    struct Job {
        uint id;
        address client;
        address freelancer;
        string description;
        uint256 budget;
        JobStatus status;
    }

    uint public jobCounter;
    mapping(uint => Job) public jobs;

    event JobPosted(uint jobId, address indexed client, string description, uint256 budget);
    event JobAccepted(uint jobId, address indexed freelancer);
    event JobCompleted(uint jobId);
    event PaymentReleased(uint jobId, address indexed freelancer, uint256 amount);

    function postJob(string calldata _description) external payable {
        require(msg.value > 0, "Budget must be greater than zero");
        jobCounter++;
        jobs[jobCounter] = Job({
            id: jobCounter,
            client: msg.sender,
            freelancer: address(0),
            description: _description,
            budget: msg.value,
            status: JobStatus.Open
        });
        emit JobPosted(jobCounter, msg.sender, _description, msg.value);
    }

    function acceptJob(uint _jobId) external {
        Job storage job = jobs[_jobId];
        require(job.status == JobStatus.Open, "Job not open");
        require(job.client != msg.sender, "Client cannot accept their own job");
        job.freelancer = msg.sender;
        job.status = JobStatus.InProgress;
        emit JobAccepted(_jobId, msg.sender);
    }

    function markCompleted(uint _jobId) external {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.freelancer, "Only freelancer can mark job as completed");
        require(job.status == JobStatus.InProgress, "Job not in progress");
        job.status = JobStatus.Completed;
        emit JobCompleted(_jobId);
    }

    function releasePayment(uint _jobId) external {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.client, "Only client can release payment");
        require(job.status == JobStatus.Completed, "Job not completed yet");
        payable(job.freelancer).transfer(job.budget);
        emit PaymentReleased(_jobId, job.freelancer, job.budget);
    }
}
