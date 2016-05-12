# FVN
Fixed-volume-neighborhood approach in multiclass recommendation based on binary feedback

Nature of the problem:
Suppose we have Nv numerical (predictor) variables, 1 categorial variable, and a binary response. When given a query with Nv variables, which category do we choose to optimize the response?

Example 1:
Consider the record of customers watching movies in a theater. We know the basic customer info: age, distance from theater, monthly movie budget etc; we know the environmental data: outdoor temporature, economic index etc; we know the movie genre; and we know the feedback after the movie to be positive or negative. For a given set of customer and environmental data, what genre do we recommend to get a positive feedback?

About the "positive feedback":
While the goal is to let the feedback be as positive as possible, there are 2 different approaches--1. choose the genre that will give the highest positive-feedback-rate 2. choose the genre that will give the most positive-feedback customers.

Fixed-volume-neighborhood:
All predictor variables are numeric so the distance-based algorithm is valid. A fixed-volume in the variable space is defined instead of a fixed number of neighbors so that the highly sparse areas are without recommendation.
