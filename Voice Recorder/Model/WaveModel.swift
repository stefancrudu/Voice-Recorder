//
//  WaveModel.swift
//  Voice Recorder
//
//  Created by Stefan Crudu on 14.03.2021.
//

import UIKit

class WaveModel: UIView {
    var frequency:CGFloat = 1.5
    let idleAmplitude:CGFloat = 0.01
    let phaseShift:CGFloat = -0.15
    let density:CGFloat = 1.0
    let primaryLineWidth:CGFloat = 1.5
    let secondaryLineWidth:CGFloat = 0.5
    let numberOfWaves:Int = 6
    var waveColor:UIColor = UIColor.red
    var amplitude:CGFloat = 1.0 {
        didSet {
            amplitude = max(amplitude, self.idleAmplitude)
            self.setNeedsDisplay()
        }
    }
    var phase:CGFloat = 0.0

    override func draw(_ rect: CGRect) {
        func drawWave(_ index:Int, maxAmplitude:CGFloat, normedAmplitude:CGFloat) {
            let path = UIBezierPath()
            let mid = self.bounds.width/2.0
            
            path.lineWidth = index == 0 ? self.primaryLineWidth : self.secondaryLineWidth
            
            for x in Swift.stride(from:0, to:self.bounds.width + self.density, by:self.density) {
                // Parabolic scaling
                let scaling = -pow(1 / mid * (x - mid), 2) + 1
                let y = scaling * maxAmplitude * normedAmplitude * sin(CGFloat(2 * Double.pi) * self.frequency * (x / self.bounds.width)  + self.phase) + self.bounds.height/2.0
                if x == 0 {
                    path.move(to: CGPoint(x:x, y:y))
                } else {
                    path.addLine(to: CGPoint(x:x, y:y))
                }
            }
            path.stroke()
        }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setAllowsAntialiasing(true)
        
        self.backgroundColor?.set()
        context?.fill(rect)
        
        let halfHeight = self.bounds.height / 2.0
        let maxAmplitude = halfHeight - self.primaryLineWidth
        
        for i in 0 ..< self.numberOfWaves {
            let progress = 1.0 - CGFloat(i) / CGFloat(self.numberOfWaves)
            let normedAmplitude = (1.5 * progress - 0.8) * self.amplitude
            let multiplier = min(1.0, (progress/3.0*2.0) + (1.0/3.0))
            self.waveColor.withAlphaComponent(multiplier * self.waveColor.cgColor.alpha).set()
            drawWave(i, maxAmplitude: maxAmplitude, normedAmplitude: normedAmplitude)
        }
        self.phase += self.phaseShift
    }
}
