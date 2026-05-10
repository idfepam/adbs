
from mrjob.job import MRJob
from mrjob.step import MRStep
from mrjob.util import log_to_stream
from mr3px.csvprotocol import CsvProtocol
import csv


def parse_id(value):
    """Parse a possibly-float id like '8.0' to int 8. Returns None if empty."""
    value = value.strip()
    if not value:
        return None
    try:
        return int(float(value))
    except (ValueError, TypeError):
        return None


class MyMRJob1(MRJob):

    OUTPUT_PROTOCOL = CsvProtocol

    def set_up_logging(cls, quiet=False, verbose=False, stream=None):
        log_to_stream(name='mrjob', debug=verbose, stream=stream)
        log_to_stream(name='__main__', debug=verbose, stream=stream)

    # ---- Round 1: key by post_id to join answers with their comments ----

    def mapper_join_by_post(self, _, line):
        row = next(csv.reader([line]))

        if len(row) == 20:                        # posts.csv
            if row[0] == 'id':
                return
            post_id   = parse_id(row[0])
            owner     = parse_id(row[13])         # owneruserid
            post_type = parse_id(row[15])         # posttypeid

            if post_id is None or owner is None or post_type is None:
                return

            if post_type == 1:                    # question
                yield str(post_id), ('Q', owner)
            elif post_type == 2:                  # answer
                parent_id = parse_id(row[14])     # parentid = question id
                if parent_id is None:
                    return
                yield str(post_id), ('A', parent_id, owner)

        elif len(row) == 6:                       # comments.csv
            if row[0] == 'id':
                return
            post_id = parse_id(row[2])            # postid (the answer)
            user_id = parse_id(row[5])            # userid (the commenter)

            if post_id is None or user_id is None:
                return
            yield str(post_id), ('C', user_id)

    def reducer_join_by_post(self, post_id, values):
        questions = []
        answers   = []
        comments  = []

        for v in values:
            if   v[0] == 'Q':  questions.append(v)
            elif v[0] == 'A':  answers.append(v)
            elif v[0] == 'C':  comments.append(v)

        # pass question rows through, still keyed by their own post_id
        for q in questions:
            yield post_id, ('Q', q[1])

        # for every (answer, comment) pair, re-key by question_id
        for a in answers:
            question_id  = str(a[1])
            answer_owner = a[2]
            for c in comments:
                yield question_id, ('AC', answer_owner, c[1])

    # ---- Round 2: key by question_id to attach the question owner ----

    def mapper_identity(self, key, value):
        yield key, value

    def reducer_attach_question(self, question_id, values):
        question_owner = None
        pairs = []

        for v in values:
            if v[0] == 'Q':
                question_owner = v[1]
            elif v[0] == 'AC':
                pairs.append((v[1], v[2]))

        if question_owner is not None:
            for answer_owner, commenter in sorted(pairs):
                yield None, (question_owner, answer_owner, commenter)

    def steps(self):
        return [
            MRStep(mapper=self.mapper_join_by_post,
                   reducer=self.reducer_join_by_post),
            MRStep(mapper=self.mapper_identity,
                   reducer=self.reducer_attach_question),
        ]


if __name__ == '__main__':
    MyMRJob1.run()
