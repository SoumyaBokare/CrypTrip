// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RideSharing is Ownable {
  bool private initialized;

  constructor(address initialOwner) Ownable(initialOwner) {
    initialized = true;
  }

  using SafeMath for uint256;

  enum CarType {
    Sedan,
    SUV,
    Hatchback,
    Rickshaw,
    Coupe
  }

  enum RideStatus {
    Requested,
    Offered,
    Accepted,
    Completed,
    Cancelled
  }

  struct User {
    uint reputation;
    uint totalRides;
    uint totalPayments;
  }

  struct Driver {
    uint reputation;
    uint totalRides;
    uint totalPayments;
  }

  struct RideRequest {
    uint id;
    address requester;
    uint origin; // Location (hashed for privacy)
    uint destination; // Location (hashed for privacy)
    uint startTime;
    CarType carType; // Use CarType enum
    uint maxPrice; // Maximum price rider is willing to pay (in tokens)
    RideStatus status; // Define RideStatus enum (e.g., Requested, Offered, Accepted, Completed, Cancelled)
  }

  struct RideOffer {
    uint rideRequestId;
    address driver;
    uint price;
    uint eta; // Estimated Time of Arrival
  }

  mapping(address => User) public users;
  mapping(address => Driver) public drivers;
  mapping(uint => RideRequest) public rideRequests; // Mapping for ride requests
  mapping(uint => RideOffer) public rideOffers; // Mapping for ride offers

  ERC20 public token;

  // Function to create a ride request
  function createRideRequest(uint _origin, uint _destination, CarType _carType, uint _maxPrice) public {
    require(users[msg.sender].reputation >= 50, "User reputation must be at least 50 to create a ride request");
    uint rideId = uint(keccak256(abi.encodePacked(msg.sender, _origin, _destination, block.timestamp)));
    RideRequest memory newRequest = RideRequest({
      id: rideId,
      requester: msg.sender,
      origin: _origin,
      destination: _destination,
      startTime: block.timestamp,
      carType: _carType,
      maxPrice: _maxPrice,
      status: RideStatus.Requested
    });
    rideRequests[rideId] = newRequest;
  }

  // Function to make a ride offer for an existing request
  function makeRideOffer(uint _rideRequestId, uint _price, uint _eta) public {
    require(drivers[msg.sender].reputation >= 50, "Driver reputation must be at least 50 to make a ride offer");
    RideRequest storage request = rideRequests[_rideRequestId];
    require(request.status == RideStatus.Requested, "Ride request status must be Requested");
    RideOffer memory newOffer = RideOffer({
      rideRequestId: _rideRequestId,
      driver: msg.sender,
      price: _price,
      eta: _eta
    });
    rideOffers[_rideRequestId] = newOffer;
    request.status = RideStatus.Offered;
  }

  function initiateRide(address _driver, uint _rideRequestId) public {
    RideRequest storage rideRequest = rideRequests[_rideRequestId];
    require(rideRequest.status == RideStatus.Offered, "Ride must be offered before initiation");
    require(msg.sender == rideRequest.requester, "Only requester can initiate the ride");

    uint startTime = block.timestamp;
    uint endTime = startTime + 30 minutes; // Example: assuming ride duration is 30 minutes
    uint fare = calculateFare(startTime, endTime); // Pass both start and end time

    rideRequest.status = RideStatus.Completed;
    users[rideRequest.requester].totalPayments += fare;
    drivers[_driver].totalPayments += fare;
    users[rideRequest.requester].totalRides++;
    drivers[_driver].totalRides++;

    // Update reputation based on completed ride (logic not implemented yet)
    updateReputation(rideRequest.requester, true);
    updateReputation(_driver, false);

    // Transfer token from requester to driver
    token.transferFrom(rideRequest.requester, _driver, fare);
  }

  function calculateFare(uint _startTime, uint _endTime) private pure returns (uint) {
    // Assuming fare is calculated based on time difference in minutes
    uint timeDifference = (_endTime - _startTime) / 60;
    return timeDifference * 1 ether; // This is a simple example, you can adjust this as per your requirements
  }

  function updateReputation(address _userOrDriver, bool _isUser) private {
    if (_isUser) {
      users[_userOrDriver].reputation = calculateReputation(users[_userOrDriver].totalPayments, users[_userOrDriver].totalRides);
    } else {
      drivers[_userOrDriver].reputation = calculateReputation(drivers[_userOrDriver].totalPayments, drivers[_userOrDriver].totalRides);
    }
  }

  function calculateReputation(uint _totalPayments, uint _totalRides) private pure returns (uint) {
    // Example reputation calculation
    return _totalPayments / _totalRides;
  }
}
