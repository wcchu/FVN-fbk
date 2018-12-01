# Fixed-volume neighborhood classifier with binary feedback

Nature of the problem:
Suppose we have n numerical (predictor) variables Vp = [V1, ... Vn], 1 categorial variable Vc, and a binary response R. When given a query with Vp, which category in Vc do we choose to "optimize" the response?

Example 1:
Consider the record of customers watching movies in a theater. We know the basic customer info: age, distance from theater, monthly movie budget etc; we know the environmental data: outdoor temperature, economic index etc; we know the movie genre; and we know the feedback after the movie to be positive or negative. For a given set of customer and environmental data Vp, what genre Vc do we recommend to get a positive feedback (R = 1)?

(1) Fixed-volume-neighborhood approach

All predictor variables Vp are numeric so the distance-based algorithm is valid. While kNN finds k nearest neighbors, we instead find all the data points within a fixed-volume in the variable space, so that the highly sparse areas are without recommendation.

About the "positive feedback":
While the goal is to let the feedback be as positive as possible, there are 2 different sub approaches--1. choose the genre that will give the highest positive-feedback-rate, 2. choose the genre that will give as many positive-feedback customers as possible.

(2) Binary probablity approach

First treat Vc as another predictor variable to train the data, and get a model M where (Vp, Vc) is the input and R is the output. When we are given a set of "actual" predictor variables Vp(0), we run through all possible Vc and throw each (Vp(0), Vc(i)) for i = 1:number_of_classes to model M and get R(i). Then we pick the Vc(i) that gives the highest probability of R(i) = 1. The model M can be trained with any binary classifier.
