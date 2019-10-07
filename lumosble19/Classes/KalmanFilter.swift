//
// Created by yaoyu on 2019-03-07
// Copyright (c) 2019 fishare. All rights reserved.
//

 /**
* Create 1-dimensional kalman filter
* @param  {Number} options.R Process noise
* @param  {Number} options.Q Measurement noise
* @param  {Number} options.A State vector
* @param  {Number} options.B Control vector
* @param  {Number} options.C Measurement vector
* @return {KalmanFilter}
*/
public class KalmanFilter{
    var R:Double = 1
    var Q:Double = 1
    var A:Double = 1
    var B:Double = 0
    var C:Double = 1

    var cov:Double = Double.nan
    var x:Double = Double.nan
    init() {}
    init(R:Double, Q:Double) {}
    init(R:Double, Q:Double, A:Double, B:Double, C:Double) {}
/**
* Filter a new value
* @param  {Number} z Measurement
* @param  {Number} u Control
* @return {Number}
*/
func filter(_ z:Double, _ u:Double = 0) -> Double {
    if (x.isNaN) {
        x = (1 / C) * z;
        cov = (1 / C) * Q * (1 / C);
    }
    else {
        // Compute prediction
        let predX = predict(u);
        let predCov = uncertainty();

        // Kalman gain
        let K = predCov * C * (1 / ((C * predCov * C) + Q));

        // Correction
        x = predX + K * (z - (C * predX));
        cov = predCov - (K * C * predCov);
    }

    return x;
}

/**
* Predict next value
* @param  {Number} [u] Control
* @return {Number}
*/
func predict(_ u:Double = 0) -> Double {
    return (A * x) + (B * u);
}

/**
* Return uncertainty of filter
* @return {Number}
*/
func uncertainty() -> Double {
    return ((A * cov) * A) + R;
}

/**
* Return the last filtered measurement
* @return {Number}
*/
func lastMeasurement() -> Double {
    return x;
}

/**
* Set measurement noise Q
* @param {Number} noise
*/
func setMeasurementNoise(_ noise:Double){
    Q = noise;
}

/**
* Set the process noise R
* @param {Number} noise
*/
func setProcessNoise(_ noise:Double){
    R = noise;
}

}
