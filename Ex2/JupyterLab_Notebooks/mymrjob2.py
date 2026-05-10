
from mrjob.job import MRJob
from mrjob.step import MRStep
from mrjob.util import log_to_stream
from mr3px.csvprotocol import CsvProtocol
import csv
import heapq
import logging

log = logging.getLogger(__name__)

K = 100


def parse_id(value):
    """Parse a possibly-float id like '8.0' to int 8. Returns None if empty."""
    value = value.strip()
    if not value:
        return None
    try:
        return int(float(value))
    except (ValueError, TypeError):
        return None


class MyMRJob2(MRJob):

    OUTPUT_PROTOCOL = CsvProtocol

    def set_up_logging(cls, quiet=False, verbose=False, stream=None):
        log_to_stream(name='mrjob', debug=verbose, stream=stream)
        log_to_stream(name='__main__', debug=verbose, stream=stream)

    # ---- Round 1: count posts per user, join with user info ----

    def mapper_count_posts(self, _, line):
        row = next(csv.reader([line]))

        if len(row) == 20:                           # posts.csv
            if row[0] == 'id':
                return
            owner     = parse_id(row[13])            # owneruserid
            post_type = parse_id(row[15])            # posttypeid

            if owner is None or post_type is None:
                return

            if post_type == 1:                       # question
                yield str(owner), ('Q',)
            elif post_type == 2:                     # answer
                yield str(owner), ('A',)

        elif len(row) == 10:                         # users.csv
            if row[0] == 'id':
                return
            user_id      = parse_id(row[0])          # id
            display_name = row[3]                    # displayname
            reputation   = parse_id(row[7])          # reputation

            if user_id is None or reputation is None:
                return
            yield str(user_id), ('U', display_name, reputation)

    def combiner_count_posts(self, user_id, values):
        q_count = 0
        a_count = 0
        for v in values:
            if   v[0] == 'Q':   q_count += 1
            elif v[0] == 'A':   a_count += 1
            elif v[0] == 'QA':  q_count += v[1]; a_count += v[2]
            else:               yield user_id, v     # pass 'U' through
        if q_count > 0 or a_count > 0:
            yield user_id, ('QA', q_count, a_count)

    def reducer_join_user(self, user_id, values):
        display_name = None
        reputation   = 0
        q_count      = 0
        a_count      = 0
        for v in values:
            if   v[0] == 'U':   display_name = v[1]; reputation = v[2]
            elif v[0] == 'Q':   q_count += 1
            elif v[0] == 'A':   a_count += 1
            elif v[0] == 'QA':  q_count += v[1]; a_count += v[2]

        if display_name is not None:
            yield None, (reputation, display_name, q_count, a_count)

    # ---- Round 2: pick top-K users by reputation ----

    def mapper_identity(self, key, value):
        yield key, value

    def reducer_top_k(self, _, values):
        top = heapq.nlargest(K, values, key=lambda x: x[0])
        for rank, (rep, name, qc, ac) in enumerate(top, 1):
            yield None, (name, rank, rep, qc, ac)

    def steps(self):
        return [
            MRStep(mapper=self.mapper_count_posts,
                   combiner=self.combiner_count_posts,
                   reducer=self.reducer_join_user),
            MRStep(mapper=self.mapper_identity,
                   reducer=self.reducer_top_k),
        ]


if __name__ == '__main__':
    MyMRJob2.run()
